#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: KC Braunschweig (<kcbraunschweig@gmail.com>)
# Revised:: 20121210 Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2011 Edmunds, Inc.
# License:: Apache License, Version 2.0
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require 'rubygems'
require 'base64'
require 'openssl'
require 'uri'
require 'cgi'
require 'net/http'
require 'json'
require 'highline/import'

class String
  def to_regexp
    return nil unless self.strip.match(/\A\/(.*)\/(.*)\Z/mx)
    regexp , flags = $1 , $2
    return nil if !regexp || flags =~ /[^xim]/m

    x = /x/.match(flags) && Regexp::EXTENDED
    i = /i/.match(flags) && Regexp::IGNORECASE
    m = /m/.match(flags) && Regexp::MULTILINE

    Regexp.new regexp , [x,i,m].inject(0){|a,f| f ? a+f : a }
  end
end

module CloudstackClient
  class Connection

    ASYNC_POLL_INTERVAL = 5.0
    ASYNC_TIMEOUT = 600

    def initialize(api_url, api_key, secret_key, project_name=nil, use_ssl=true)
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @project_id = nil
      @use_ssl = use_ssl
      if project_name
        project = get_project(project_name)
        if !project then
          puts "Project #{project_name} does not exist"
          exit 1
        end
        @project_id = project['id']
      end
    end

    def ui
      require 'chef/knife/core/ui'
      @ui ||= Chef::Knife::UI.new(STDOUT, STDERR, STDIN, {})
    end

    ##
    # Finds the server with the specified name.

    def get_server(name)
      params = {
          'command' => 'listVirtualMachines',
          'name' => name
      }
      json = send_request(params)
      machines = json['virtualmachine']

      if !machines || machines.empty? then
        return nil
      end

      machines.first
    end

    ##
    # Finds the public ip for a server

    def get_server_public_ip(server, cached_rules=nil)
      return nil unless server
      # find the public ip
      nic = get_server_default_nic(server)
      ssh_rule = get_ssh_port_forwarding_rule(server, cached_rules)
      if ssh_rule
        return ssh_rule['ipaddress']
      end
      #check for static NAT
      ip_addr = list_public_ip_addresses.find {|v| v['virtualmachineid'] == server['id']} unless list_public_ip_addresses.nil?
      if ip_addr
        return ip_addr['ipaddress']
      end
      nic['ipaddress']
    end

    ##
    # Returns the fully qualified domain name for a server.

    def get_server_fqdn(server)
      return nil unless server

      nic = get_server_default_nic(server) || {}
      networks = list_object('listNetworks','network') || {}

      id = nic['networkid']
      network = networks.select { |net|
        net['id'] == id
      }.first
      return nil unless network

      "#{server['name']}.#{network['networkdomain']}"
    end

    def get_server_default_nic(server)
      server['nic'].each do |nic|
        return nic if nic['isdefault']
      end
    end

    ##
    # Returns the object data based on the command, json_result parameter.

    def list_object(command, json_result, filter=nil, listall=nil, keyword=nil, name=nil, templatefilter=nil)
      params = {
          'command' => command
      }
      params['listall'] = true if listall || name || keyword || filter unless listall == false
      params['keyword'] = keyword if keyword
      params['name'] = name if name

      if templatefilter
        template = 'featured'
        template = templatefilter.downcase if ["featured","self","self-executable","executable","community"].include?(templatefilter.downcase)
        params['templateFilter'] = template
      end

      json = send_request(params)
      Chef::Log.debug("JSON (list_object) result: #{json}")

      result = json["#{json_result}"] || []
      result = data_filter(result, filter) if filter
      result
    end

    def show_object_fields(object)
      exit 1 if object.nil? || object.empty?
      object_fields = [
        ui.color('Key', :bold),
        ui.color('Type', :bold),
        ui.color('Value', :bold)
      ]
      
      object.first.sort.each do |k,v|
        object_fields << k
        object_fields << v.class.to_s
        if v.kind_of?(Array) 
          object_fields << '<Array>'
        else
          object_fields << ("#{v}").strip.to_s
        end
      end
      puts "\n"
      puts ui.list(object_fields, :uneven_columns_across, 3)
    end
    
    def check_account_access_level(l)
  
      r = list_object("listAccounts", "account", nil, false)
      n = r.first['accounttype']

      case n
        when 2 then account = "domain admin"; s = 2
        when 1 then account = "admin"; s = 3
        when 0 then account = "user"; s = 1
      end
           
      Chef::Log.debug("Account access level needed  : #{l}")
      Chef::Log.debug("Current account access level : #{s}")
      if s < l
         ui.error "Your #{account} account is not allowed to execute this command."
        exit 1
      end
    end

    ##
    # Create a new domain using the specified parameters

    def create_domain(domainname, parentdomain, networkdomain)
      if parentdomain then
        domainpath = parentdomain + "/" + domainname 
      else 
        domainpath = domainname
      end
 
      if domainname then
        if get_domain(domainpath) then
          puts "Error: Domain '#{domainpath}' already exists."
          exit 1
        end
      end

      params = {
        'command' => 'createDomain',
        'name' => domainname
      }
      if parentdomain then
        parentdomaindata = get_domain(parentdomain)
        if parentdomaindata.nil? then 
          puts "Error: Cannot find domain ID for: #{parentdomain}."
          exit 1
        else
          params['parentdomainid'] = parentdomaindata['id'] if parentdomain
        end
      end

 
      json = send_request(params)
      json['domain']
      puts json
    end

    ##
    # Deploys a new service offering using the specified parameters.

    def create_service(service_name, cpunumber, cpuspeed, displaytext, memory, 
                       domainname=nil, hosttags=nil, issystem=nil, limitcpuuse=nil, 
                       networkrate=nil, offerha=nil, storagetype=nil, systemvmtype=nil, tags=nil)

      if service_name then
        if get_service_offering(service_name) then
          puts "Error: Service '#{service_name}' already exists."
          exit 1
        end
      end

      if !cpunumber then
        puts "Error: The cpunumber parameter is missing."
        exit 1
      end

      if !cpuspeed then
        puts "Error: The cpuspeed parameter is missing."
        exit 1
      end

      if !displaytext then
        puts "Error: The displaytext parameter is missing."
        exit 1
      end

      if !memory then
        puts "Error: The memory parameter is missing."
        exit 1
      end

      params = {
        'command' => 'createServiceOffering',
        'cpunumber' => cpunumber,
        'cpuspeed' => cpuspeed,
        'displaytext' => displaytext,
        'memory' => memory,
        'name' => service_name
      }

      domain = get_domain(domainname) if domainname
      params['domainid'] = domain['id'] if domain
      params['hosttags'] = hosttags if hosttags
      params['issystem'] = issystem if issystem
      params['limitcpuuse'] = limitcpuuse if limitcpuuse
      params['networkrate'] = networkrate if networkrate
      params['offerha'] = offerha if offerha
      params['storagetype'] = storagetype if storagetype
      params['systemvmtype'] = systemvmtype if systemvmtype
      params['tags'] = tags if tags

      json = send_request(params)
      json['serviceoffering']
    end

    ##
    # Deploys a new disk offering using the specified parameters.
 
    def create_diskoffering(diskname, displaytext, disksize, domainpath=nil, tags=nil, iscustom=nil)

      if diskname then
        if get_disk_offering(diskname) then
          puts "Error: Disk offering: '#{diskname}' already exists."
          exit 1
        end
      end

      if !displaytext then
        puts "Error: The displaytext parameter is missing."
        exit 1
      end

      params = {
        'command' => 'createDiskOffering',
        'displaytext' => displaytext,
        'name' => diskname
      }
      domain = get_domain(domainpath) if domainpath
      params['domainid'] = domain['id'] if domain
      params['tags'] = tags if tags
      params['customized'] = iscustom if iscustom
      params['disksize'] = disksize unless iscustom

      json = send_request(params)
      json['diskoffering']

    end

    ##
    # Creates a new template using the specified parameters.

    def create_template(name, displaytext, ostypeid, volumeid)
      params = {
        'command' => 'createTemplate',
        'name' => name,
        'displaytext' => displaytext,
        'ostypeid' => ostypeid,
        'volumeid' => volumeid
      }

      json = send_request(params)
      json['template']
      puts json
    end

    ##
    # Deploys a new server using the specified parameters.
    # If the template name is not found this routine searches for an ISO with
    # the given name as well

    def create_server(host_name, service_name, template_name=nil, zone_name=nil, iso_name=nil, disk_name=nil, project_name=nil, network_names=[])

      if project_name then
        project = get_project(project_name)
	if !project then
	  puts "\nError: Project '#{project_name}' doesn't exist";
	  exit 1
	end
      end
      project = { 'id' => nil } if ! project
        
      if host_name then
        if get_server(host_name) then
          puts "\nError: Server '#{host_name}' already exists."
          exit 1
        end
      end

      service = get_service_offering(service_name)
      if !service then
        puts "\nError: Service offering '#{service_name}' is invalid"
        exit 1
      end

      if template_name then
        if iso_name then
	  puts "\nError: you cannot specify both a template and an iso"
	  exit 1
	end
        template = get_template(template_name)
        if !template then
          puts "Error: Template '#{template_name}' is invalid"
          exit 1
	end
      end

      if iso_name then
      	template = get_iso(iso_name) 
	if !template then
          puts "Error: ISO '#{template_name}' is invalid"
          exit 1
	end
      end

      if !template then
	puts "\nError: You need to specify a template or ISO"
	exit 1
      end

      if disk_name then
        disk = get_disk_offering(disk_name)
	if !disk then
	  puts "\nError: Disk '#{disk_name}' is invalid"
	  exit 1
	end
      end

      zone = zone_name ? get_zone(zone_name) : get_default_zone
      if !zone then
        msg = zone_name ? "Zone '#{zone_name}' is invalid" : "No default zone found"
        puts "Error: #{msg}"
        exit 1
      end

      networks = []
      network_names.each do |name|
        network = get_network(name)
        if !network then
          puts "Error: Network '#{name}' not found"
          exit 1
        end
        networks << get_network(name)
      end
      if networks.empty? then
        networks << get_default_network(zone['id'])
      end
      if networks.empty? then
        puts "No default network found"
        exit 1
      end
      network_ids = networks.map { |network|
        network['id']
      }

      params = {
          'command' => 'deployVirtualMachine',
          'serviceOfferingId' => service['id'],
          'templateId' => template['id'],
          'zoneId' => zone['id'],
          'networkids' => network_ids.join(',')
      }

      params['name'] = host_name if host_name
      params['diskofferingid'] = disk['id'] if iso_name 
      params['hypervisor'] = 'XenServer'

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Deletes the server with the specified name.

    def delete_server(name)
      server = get_server(name)
      if !server || !server['id'] then
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'destroyVirtualMachine',
          'id' => server['id']
      }
      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Stops the server with the specified name.

    def stop_server(name, forced=nil)
      server = get_server(name)
      if !server || !server['id'] then
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'stopVirtualMachine',
          'id' => server['id']
      }
      params['forced'] = true if forced

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Start the server with the specified name.

    def server_action(command, json_result, server, quiet=nil, forced=nil)
      result = []
      server.each do |s|
        if s['id'] then
          params = { 'command' => command }
          case command
            when "migrateVirtualMachine" then params['virtualmachineid'] = s['id']
            else params['id'] = s['id']
          end  
          
          if quiet then
            print "Starting host: " + s['name'] if command == "startVirtualMachine"
            print "Stopping host: " + s['name'] if command == "stopVirtualMachine"
            json = send_async_request(params)
            result << json["#{json_result}"]
          else
            object_fields = [
              ui.color('Key', :bold),
              ui.color('Value', :bold)
            ]

            object_fields << ui.color("Name", :yellow, :bold)
            object_fields << s['name'].to_s
            object_fields << ui.color("Public IP", :yellow, :bold)
            object_fields << (get_server_public_ip(s) || 'N/A')
            object_fields << ui.color("Service", :yellow, :bold)
            object_fields << s['serviceofferingname'].to_s
            object_fields << ui.color("Template", :yellow, :bold)
            object_fields << s['templatename']
            object_fields << ui.color("Domain", :yellow, :bold)
            object_fields << s['domain']
            object_fields << ui.color("Zone", :yellow, :bold)
            object_fields << s['zonename']
            object_fields << ui.color("State", :yellow, :bold)
            object_fields << s['state']
          
            puts "\n"
            puts ui.list(object_fields, :uneven_columns_across, 2)
            response = yesno("Do you really want to start this server") if command == "startVirtualMachine"
            response = yesno("Do you really want to stop this server") if command == "stopVirtualMachine"

            if response
              print "Starting host: " + s['name'] if command == "startVirtualMachine"
              print "Stopping host: " + s['name'] if command == "stopVirtualMachine"
              json = send_async_request(params)
              result << json["#{json_result}"]
            end
          end
          puts "\n"
        end
      end
      result
    end


    def yesno(prompt = 'Continue?', default = true)
      a = ''
      s = default ? '[Y/n]' : '[y/N]'
      d = default ? 'y' : 'n'
      until %w[y n].include? a
        a = ask("#{prompt} #{s} ") { |q| q.limit = 1; q.case = :downcase }
        a = d if a.length == 0
      end
      a == 'y'
    end


    def start_server(name)
      server = get_server(name)
      if !server || !server['id'] then
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'startVirtualMachine',
          'id' => server['id']
      }

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Reboot the server with the specified name.

    def reboot_server(name)
      server = get_server(name)
      if !server || !server['id'] then
        puts "Error: Virtual machine '#{name}' does not exist"
        exit 1
      end

      params = {
          'command' => 'rebootVirtualMachine',
          'id' => server['id']
      }

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Finds the service offering with the specified name.

    def get_service_offering(name)
      params = {
          'command' => 'listServiceOfferings'
      }
      json = send_request(params)

      services = json['serviceoffering']
      return nil unless services

      services.each { |s|
        if s['name'] == name then
          return s
        end
      }
      nil
    end

    def get_disk_offering(name)
      params = {
        'command' => 'listDiskOfferings'
      }
      json = send_request(params)

      diskoffering = json['diskoffering']
      return nil unless diskoffering

      diskoffering.each { |s|
        if s['name'] == name then
          return s
        end
      }
      nil
    end

    def get_domain(domainname)
      params = {
        'command' => 'listDomains',
        'listall' => 'true'
      }
      json = send_request(params)

      domaindata = json['domain']
      return nil unless domaindata
      
      domainname = "root/" + domainname unless domainname =~ /^root.*$/i 

      domaindata.each { |domain|
        if domain['path'].downcase == (domainname.downcase).gsub("\\","/") then
          return domain
        end
      }
      nil
    end

    # Finds the template with the specified name.

    def get_template(name)

      # TODO: use name parameter
      # listTemplates in CloudStack 2.2 doesn't seem to work
      # when the name parameter is specified. When this is fixed,
      # the name parameter should be added to the request.
      params = {
          'command' => 'listTemplates',
          'templateFilter' => 'executable'
      }
      json = send_request(params)

      templates = json['template']
      if !templates then
        return nil
      end

      templates.each { |t|
        if t['name'] == name then
          return t
        end
      }

      nil
    end

    # Finds the template with the specified name.

    def get_iso(name)

      # TODO: use name parameter
      params = {
          'command' => 'listIsos',
          'templateFilter' => 'executable'
      }
      json = send_request(params)

      isos = json['iso']
      if !isos then
        return nil
      end

      isos.each { |i|
        if i['name'] == name then
          return i
        end
      }

      nil
    end

    #Fetch project with the specified name
    def get_project(name)
      params = {
        'command' => 'listProjects',
        'listall' => 'true'
      }

      json = send_request(params)
      projects = json['project']
      return nil unless projects
      projects.each { |n|
        if n['name'] == name then
          return n
        end
      }

      nil
    end

    # Filter data based on user input which can be string or regexp
    def data_filter(data, filters)
      filters.split(',').each do |filter|
        field = filter.split(':')[0].strip.downcase
        search = filter.split(':')[1].strip
        if search =~ /^\/.*\/?/
          data = data.find_all { |k| k["#{field}"].to_s =~ search.to_regexp } if field && search
        else
          data = data.find_all { |k| k["#{field}"].to_s == "#{search}" } if field && search
        end
      end
      data
    end


    ##
    # Finds the network with the specified name.

    def get_network(name)
      params = {
          'command' => 'listNetworks'
      }
      json = send_request(params)

      networks = json['network']
      return nil unless networks

      networks.each { |n|
        if n['name'] == name then
          return n
        end
      }

      nil
    end

    ##
    # Finds the default network.

    def get_default_network(zone)
      params = {
          'command' => 'listNetworks',
          'isDefault' => true,
          'zoneid' => zone
      }
      json = send_request(params)

      networks = json['network']
      return nil if !networks || networks.empty?

      default = networks.first
      return default if networks.length == 1

      networks.each { |n|
        if n['type'] == 'Direct' then
          default = n
          break
        end
      }

      default
    end

   ##
    # Finds the zone with the specified name.

    def get_zone(name)
      params = {
          'command' => 'listZones',
          'available' => 'true'
      }
      json = send_request(params)

      networks = json['zone']
      return nil unless networks

      networks.each { |z|
        if z['name'] == name then
          return z
        end
      }

      nil
    end

    ##
    # Finds the default zone for your account.

    def get_default_zone
      params = {
          'command' => 'listZones',
          'available' => 'true'
      }
      json = send_request(params)

      zones = json['zone']
      return nil unless zones

      zones.first
    end

    ##
    # Finds the public ip address for a given ip address string.

    def get_public_ip_address(ip_address)
      params = {
          'command' => 'listPublicIpAddresses',
          'ipaddress' => ip_address
      }
      json = send_request(params)
      return nil unless json['publicipaddress']
      json['publicipaddress'].first
    end

    def list_public_ip_addresses()
      params = { 'command' => 'listPublicIpAddresses'}

      json = send_request(params)
      return json['publicipaddress']
    end
    ##
    # Acquires and associates a public IP to an account.

    def associate_ip_address(zone_id, networks)
      params = {
          'command' => 'associateIpAddress',
          'zoneId' => zone_id
      }
      #Choose the first network from the list
      if networks.size > 0
        params['networkId'] = get_network(networks.first)['id']
      else
        default_network = get_default_network(zone_id)
        params['networkId'] = default_network['id']
      end
      print "params: #{params}"
      json = send_async_request(params)
      json['ipaddress']
    end

    def enable_static_nat(ipaddress_id, virtualmachine_id)
      params = {
        'command' => 'enableStaticNat',
        'ipAddressId' => ipaddress_id,
        'virtualmachineId' => virtualmachine_id
      }
      send_request(params)
    end

    def disable_static_nat(ipaddress)
      params = {
        'command' => 'disableStaticNat',
        'ipAddressId' => ipaddress['id']
      }
      send_async_request(params)
    end

    def create_ip_fwd_rule(ipaddress_id, protocol, start_port, end_port)
      params = {
        'command' => 'createIpForwardingRule',
        'ipaddressId' => ipaddress_id,
        'protocol' => protocol,
        'startport' =>  start_port,
        'endport' => end_port
      }

      send_async_request(params)
    end


    ##
    # Disassociates an ip address from the account.
    #
    # Returns true if successful, false otherwise.

    def disassociate_ip_address(id)
      params = {
          'command' => 'disassociateIpAddress',
          'id' => id
      }
      json = send_async_request(params)
      json['success']
    end

    ##
    # Lists all port forwarding rules.

    def list_port_forwarding_rules(ip_address_id=nil)
      params = {
          'command' => 'listPortForwardingRules'
      }
      params['ipAddressId'] = ip_address_id if ip_address_id
      json = send_request(params)
      json['portforwardingrule']
    end

    ##
    # Gets the SSH port forwarding rule for the specified server.

    def get_ssh_port_forwarding_rule(server, cached_rules=nil)
      rules = cached_rules || list_port_forwarding_rules || []
      rules.find_all { |r|
        r['virtualmachineid'] == server['id'] &&
            r['privateport'] == '22'&&
            r['publicport'] == '22'
      }.first
    end

    ##
    # Creates a port forwarding rule.

    def create_port_forwarding_rule(ip_address_id, private_port, protocol, public_port, virtual_machine_id)
      params = {
          'command' => 'createPortForwardingRule',
          'ipAddressId' => ip_address_id,
          'privatePort' => private_port,
          'protocol' => protocol,
          'publicPort' => public_port,
          'virtualMachineId' => virtual_machine_id
      }
      json = send_async_request(params)
      json['portforwardingrule']
    end

    ##
    # Sends a synchronous request to the CloudStack API and returns the response as a Hash.
    #
    # The wrapper element of the response (e.g. mycommandresponse) is discarded and the
    # contents of that element are returned.

    def send_request(params)
      params['projectId'] = @project_id if @project_id
      params['response'] = 'json'
      params['apiKey'] = @api_key
      puts params
      #exit 255

      params_arr = []
      params.sort.each { |elem|
        params_arr << elem[0].to_s + '=' + elem[1].to_s
      }
      data = params_arr.join('&')
      encoded_data = URI.encode(data.downcase).gsub('+', '%20').gsub(',', '%2c').gsub(' ','%20')
      signature = OpenSSL::HMAC.digest('sha1', @secret_key, encoded_data)
      signature = Base64.encode64(signature).chomp
      signature = CGI.escape(signature)

      url = "#{@api_url}?#{data}&signature=#{signature}"
      url = url.gsub('+', '%20').gsub(' ','%20')
      uri = URI.parse(url)

      Chef::Log.debug("URL: #{url}" )
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @use_ssl
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if !response.is_a?(Net::HTTPOK) then
        puts "Error #{response.code}: #{response.message}"
        puts JSON.pretty_generate(JSON.parse(response.body))
        puts "URL: #{url}"
        exit 1
      end

      json = JSON.parse(response.body)
      json[params['command'].downcase + 'response']
    end

    ##
    # Sends an asynchronous request and waits for the response.
    #
    # The contents of the 'jobresult' element are returned upon completion of the command.

    def send_async_request(params)

      json = send_request(params)

      params = {
          'command' => 'queryAsyncJobResult',
          'jobId' => json['jobid']
      }

      max_tries = (ASYNC_TIMEOUT / ASYNC_POLL_INTERVAL).round
      max_tries.times do
        json = send_request(params)
        status = json['jobstatus']

        print "."

        if status == 1 then
          return json['jobresult']
        elsif status == 2 then
          print "\n"
          puts "Request failed (#{json['jobresultcode']}): #{json['jobresult']}"
          exit 1
        end

        STDOUT.flush
        sleep ASYNC_POLL_INTERVAL
      end

      print "\n"
      puts "Error: Asynchronous request timed out"
      exit 1
    end

  end # class
end

