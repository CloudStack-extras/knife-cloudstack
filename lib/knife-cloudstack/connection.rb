#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: KC Braunschweig (<kcbraunschweig@gmail.com>)
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Author:: Frank Breedijk (<fbreedijk@schubergphilis.com>)
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
require 'knife-cloudstack/string_to_regexp'

module CloudstackClient
  class Connection

    ASYNC_POLL_INTERVAL = 5.0
    ASYNC_TIMEOUT = 600

    def initialize(api_url, api_key, secret_key, project_name=nil, account=nil, use_ssl=true)
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @project_id = nil
      @use_ssl = use_ssl
      @account = account
      if project_name
        project = get_project(project_name)
        if !project then
          puts "Project #{project_name} does not exist"
          exit 1
        end
        @project_id = project['id']
      end

    end

    ##
    # Finds the server with the specified name.

    def get_server(name)
      params = {
          'command' => 'listVirtualMachines',
          'name' => name
      }
      # if @project_id
      #   params['projectId'] = @project_id
      # end
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
      ip_addr = list_public_ip_addresses.find {|v| v['virtualmachineid'] == server['id']}
      if ip_addr
        return ip_addr['ipaddress']
      end
      nic['ipaddress'] || []
    end

    ##
    # Returns the fully qualified domain name for a server.

    def get_server_fqdn(server)
      return nil unless server

      nic = get_server_default_nic(server) || {}
      networks = list_networks || {}

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
    # List all the objects based on the command that is specified.
    
    def list_object(command, json_result, filter=nil, listall=nil, keyword=nil, name=nil, templatefilter=nil)
      params = {
          'command' => command
      }
      params['listall'] = true if listall || name || keyword unless listall == false
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

    ##
    # Lists all the servers in your account.

    def list_servers
      params = {
          'command' => 'listVirtualMachines'
      }
      json = send_request(params)
      json['virtualmachine'] || []
    end

    ##
    # Deploys a new server using the specified parameters.

    def create_server(host_name, service_name, template_name, zone_name=nil, network_names=[], extra_params)

      if host_name then
        if get_server(host_name) then
          puts "Error: Server '#{host_name}' already exists."
          exit 1
        end
      end

      service = get_service_offering(service_name)
      if !service then
        puts "Error: Service offering '#{service_name}' is invalid"
        exit 1
      end

      template = get_template(template_name)
      if !template then
        puts "Error: Template '#{template_name}' is invalid"
        exit 1
      end

      zone = zone_name ? get_zone(zone_name) : get_default_zone
      if !zone then
        msg = zone_name ? "Zone '#{zone_name}' is invalid" : "No default zone found"
        puts "Error: #{msg}"
        exit 1
      end

      if not @account.nil?
        if extra_params.include?('domainname')
          domain = get_domain(extra_params['domainname'])
          extra_params.delete 'domainname'
        else
          domain = get_default_domain
        end
        extra_params['domainId'] = domain['id']
      end

      if extra_params.include?('securitygroups')
        securitygroups = extra_params['securitygroups'].map{|s| get_securitygroup(s)['id'] }

        extra_params.delete 'securitygroups'
        extra_params['securitygroupids'] = securitygroups.join(',') if securitygroups.length > 0
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

      # Can't specify network Ids in Basic zone
      if networks.length > 0 and networks[0]['name'] == 'guestNetworkForBasicZone' then
          network_ids = nil
      end

      params = {
          'command' => 'deployVirtualMachine',
          'serviceOfferingId' => service['id'],
          'templateId' => template['id'],
          'zoneId' => zone['id'],
          'networkids' => network_ids ? network_ids.join(',') : nil
      }

      params.merge!(extra_params) if extra_params

      params['name'] = host_name if host_name
      params['account'] = @account if not @account.nil?

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Deletes the server with the specified name.
    #

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
    #

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
    #

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
    #

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

      # TODO: use name parameter
      # listServiceOfferings in CloudStack 2.2 doesn't seem to work
      # when the name parameter is specified. When this is fixed,
      # the name parameter should be added to the request.
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

    ##
    # Lists all available service offerings.

    def list_service_offerings
      params = {
          'command' => 'listServiceOfferings'
      }
      json = send_request(params)
      json['serviceoffering'] || []
    end

    ##
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

    ##
    # Lists all templates that match the specified filter.
    #
    # Allowable filter values are:
    #
    # * featured - templates that are featured and are public
    # * self - templates that have been registered/created by the owner
    # * self-executable - templates that have been registered/created by the owner that can be used to deploy a new VM
    # * executable - all templates that can be used to deploy a new VM
    # * community - templates that are public

    def list_templates(filter)
      filter ||= 'featured'
      params = {
          'command' => 'listTemplates',
          'templateFilter' => filter
      }
      json = send_request(params)
      json['template'] || []
    end

    #Fetch project with the specified name
    def get_project(name)
      params = {
        'command' => 'listProjects',
	'listall' => true
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

    ##
    # Filter data on regex or just on string

    def data_filter(data, filters)
      filters.split(',').each do |filter|
        field = filter.split(':').first.strip.downcase
        search = filter.split(':').last.strip
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
    # Lists all available networks.

    def list_networks
      params = {
          'command' => 'listNetworks'
      }
      json = send_request(params)
      json['network'] || []
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
    # Lists all available zones.

    def list_zones
      params = {
          'command' => 'listZones',
          'available' => 'true'
      }
      json = send_request(params)
      json['zone'] || []
    end

    ##
    # Finds the domain with the specified name.

    def get_domain(name)
      params = {
        'command' => 'listDomains',
      }
      json = send_request(params)
      domains = json['domain']

      domains.each { |z|
        if z['name'] == name then
          return z
        end
      }
    end

    ##
    # Finds the default domain for your account

    def get_default_domain
      params = {
        'command' => 'listDomains',
      }
      json = send_request(params)
      domains = json['domain']

      domains.first
    end

    ##
    # Finds the security group with the secific name.

    def get_securitygroup(name)
      params = {
        'command' => 'listSecurityGroups'
      }
      json = send_request(params)
      securitygroups = json['securitygroup']

      securitygroups.each { |z|
        if z['name'] == name then
          return z
        end
      }
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
      return json['publicipaddress'] || []
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

    def create_firewall_rule(ipaddress_id, protocol, param3, param4, cidr_list)
      if protocol == "ICMP"
        params = {
          'command' => 'createFirewallRule',
          'ipaddressId' => ipaddress_id,
          'protocol' => protocol,
          'icmptype' =>  param3,
          'icmpcode' => param4,
          'cidrlist' => cidr_list
        }
      else
        params = {
          'command' => 'createFirewallRule',
          'ipaddressId' => ipaddress_id,
          'protocol' => protocol,
          'startport' =>  param3,
          'endport' => param4,
          'cidrlist' => cidr_list
        }
      end
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
      if @project_id
        params['projectId'] = @project_id
      end
      params['response'] = 'json'
      params['apiKey'] = @api_key
      params['account'] = @account if not @account.nil?

      params_arr = []
      params.sort.each { |elem|
        params_arr << elem[0].to_s + '=' + CGI.escape(elem[1].to_s).gsub('+', '%20').gsub(' ','%20')
      }
      data = params_arr.join('&')
      signature = OpenSSL::HMAC.digest('sha1', @secret_key, data.downcase)
      signature = Base64.encode64(signature).chomp
      signature = CGI.escape(signature)

      url = "#{@api_url}?#{data}&signature=#{signature}"
      Chef::Log.debug("URL: #{url}")
      uri = URI.parse(url)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = @use_ssl
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if !response.is_a?(Net::HTTPOK) then
        case response.code
        when "432"
          puts "\n" 
          puts "Error #{response.code}: Your account does not have the right to execute this command or the command does not exist."
        else
          puts "Error #{response.code}: #{response.message}"
          puts JSON.pretty_generate(JSON.parse(response.body))
          puts "URL: #{url}"
        end
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

