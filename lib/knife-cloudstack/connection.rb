#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: KC Braunschweig (<kcbraunschweig@gmail.com>)
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Author:: Frank Breedijk (<fbreedijk@schubergphilis.com>)
# Author:: Sander van Harmelen (<svanharmelen@schubergphilis.com>)
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

  def is_uuid?
    self.strip =~ /^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$/ ? true : false
  end
end

module CloudstackClient
  class Connection

    ASYNC_POLL_INTERVAL = 5.0
    ASYNC_TIMEOUT = 600

    def initialize(api_url, api_key, secret_key, project_name=nil, no_ssl_verify=false, api_proxy=nil)
      @api_url = api_url
      @api_key = api_key
      @secret_key = secret_key
      @no_ssl_verify = no_ssl_verify
      @project_id = get_project_id(project_name) if project_name || nil
      @api_proxy = api_proxy
    end

    ##
    # Get project id
    def get_project_id(name)
      project = get_project(name)
      if !project then
        puts "Project #{project_name} does not exist"
        exit 1
      end
      project['id']
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
      machine = machines.select { |item| name == item['name'] }
      machine.first
    end

    ##
    # Finds the public ip for a server

    def get_server_public_ip(server, cached_rules=nil, cached_nat=nil)
      return nil unless server
      # find the public ip
      nic = get_server_default_nic(server)

      ssh_rule = get_ssh_port_forwarding_rule(server, cached_rules)
      return ssh_rule['ipaddress'] if ssh_rule

      winrm_rule = get_winrm_port_forwarding_rule(server, cached_rules)
      return winrm_rule['ipaddress'] if winrm_rule 

      #check for static NAT
      if cached_nat
        ip_addr = cached_nat.find {|v| v['virtualmachineid'] == server['id']}
      else
        ip_addr = list_public_ip_addresses.find {|v| v['virtualmachineid'] == server['id']}
      end
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

    def list_object(params, json_result)
      json = send_request(params)
      Chef::Log.debug("JSON (list_object) result: #{json}")

      result = json["#{json_result}"] || []
      result = data_filter(result, params['filter']) if params['filter']
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

    def create_server(host_name, service_name, template_name, disk_name=nil, zone_name=nil, network_names=[], extra_params)

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

      template = get_template(template_name, zone_name)
      template = get_iso(template_name, zone_name) unless template

      if !template then
        puts "\nError: Template / ISO name: '#{template_name}' is invalid"
        exit 1
      end

      if disk_name then
        disk = get_disk_offering(disk_name)
        if !disk then
          puts "\nError: Disk offering '#{disk_name}' is invalid"
          exit 1
        end
      end

      zone = zone_name ? get_zone(zone_name) : get_default_zone
      if !zone then
        msg = zone_name ? "Zone '#{zone_name}' is invalid" : "No default zone found"
        puts "\nError: #{msg}"
        exit 1
      end

      if zone['networktype'] != 'Basic' then
      # If this is a Basic zone no networkids are needed in the params

        networks = []
        if network_names.nil? then
          networks << get_default_network(zone['id'])
        else
          network_names.each do |name|
            network = get_network(name)
            if !network then
              puts "\nError: Network '#{name}' not found"
            end
            networks << get_network(name)
          end
        end

        if networks.empty? then
          networks << get_default_network(zone['id'])
        end
        if networks.empty? then
          puts "\nError: No default network found"
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

      else

        params = {
            'command' => 'deployVirtualMachine',
            'serviceOfferingId' => service['id'],
            'templateId' => template['id'],
            'zoneId' => zone['id']
        }

      end

      params.merge!(extra_params) if extra_params

      params['name'] = host_name if host_name
      params['diskOfferingId'] = disk['id'] if disk

      json = send_async_request(params)
      json['virtualmachine']
    end

    ##
    # Deletes the server with the specified name.
    #

    def delete_server(name)
      server = get_server(name)
      if !server || !server['id'] then
        puts "\nError: Virtual machine '#{name}' does not exist"
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
        puts "\nError: Virtual machine '#{name}' does not exist"
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
        puts "\nError: Virtual machine '#{name}' does not exist"
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
        puts "\nError: Virtual machine '#{name}' does not exist"
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
        if name.is_uuid? then
          return s if s['id'] == name
        else
          return s if s['name'] == name
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

    def list_security_groups
      params = {
          'command' => 'listSecurityGroups'
      }
      json = send_request(params)
      json['securitygroups'] || []
    end


    ##
    # Finds the template with the specified name.

    def get_template(name, zone_name=nil)

      # TODO: use name parameter
      # listTemplates in CloudStack 2.2 doesn't seem to work
      # when the name parameter is specified. When this is fixed,
      # the name parameter should be added to the request.

      zone = zone_name ? get_zone(zone_name) : get_default_zone

      params = {
          'command' => 'listTemplates',
          'templateFilter' => 'executable',
      }
      params['zoneid'] = zone['id'] if zone

      json = send_request(params)

      templates = json['template']
      return nil unless templates

      templates.each { |t|
        if name.is_uuid? then
          return t if t['id'] == name
        else
          return t if t['name'] == name
        end
      }
      nil
    end

    ##
    # Finds the iso with the specified name.

    def get_iso(name, zone_name=nil)
      zone = zone_name ? get_zone(zone_name) : get_default_zone

      params = {
          'command' => 'listIsos',
          'isoFilter' => 'executable',
      }
      params['zoneid'] = zone['id'] if zone

      json = send_request(params)
      iso = json['iso']
      return nil unless iso

      iso.each { |i|
        if name.is_uuid? then
          return i if i['id'] == name
        else
          return i if i['name'] == name
        end
      }
      nil
    end



    ##
    # Finds the disk offering with the specified name.

    def get_disk_offering(name)
      params = {
          'command' => 'listDiskOfferings',
      }
      json = send_request(params)
      disks = json['diskoffering']

      return nil if !disks

      disks.each { |d|
        return d if d['name'] == name
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
        if name.is_uuid? then
          return n if n['id'] == name
        else
          return n if n['name'] == name
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
        if name.is_uuid? then
          return n if n['id'] == name
        else
          return n if n['name'] == name
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
        if name.is_uuid? then
          return z if z['id'] == name
        else
          return z if z['name'] == name
        end
      }
      nil
    end

    def add_nic_to_vm(network_id, server_id, ipaddr=nil)
      params = {
        'command' => 'addNicToVirtualMachine',
        'networkid' => network_id,
        'virtualmachineid' => server_id,
      }

      unless ipaddr.nil?
        params['ipaddress'] = ipaddr
      end

      json = send_async_request(params)
      json['virtualmachine']
    end

    def remove_nic_from_vm(nic_id, server_id)
      params = {
        'command' => 'removeNicFromVirtualMachine',
        'nicid' => nic_id,
        'virtualmachineid' => server_id,
      }

      json = send_async_request(params)
      json['virtualmachine']
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
      # zones.sort! # sort zones so we always return the same zone
      # !this gives error in our production environment so need to retest this
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

    def list_public_ip_addresses(listall=false)
      params = { 'command' => 'listPublicIpAddresses' } 
      params['listall'] = listall

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
      if networks.nil? || networks.empty?
        default_network = get_default_network(zone_id)
        params['networkId'] = default_network['id']
      else
        params['networkId'] = get_network(networks.first)['id']
      end
      Chef::Log.debug("associate ip params: #{params}")
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

    def list_port_forwarding_rules(ip_address_id=nil, listall=false)
      params = { 'command' => 'listPortForwardingRules' }
      params['ipAddressId'] = ip_address_id if ip_address_id
      params['listall'] = listall
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
    # Gets the WINRM port forwarding rule for the specified server.

    def get_winrm_port_forwarding_rule(server, cached_rules=nil)
      rules = cached_rules || list_port_forwarding_rules || []
      rules.find_all { |r|
        r['virtualmachineid'] == server['id'] &&
           (r['privateport'] == '5985' &&
            r['publicport'] == '5985') ||
           (r['privateport'] == '5986' &&
            r['publicport'] == '5986')
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

    def http_client_builder
      http_proxy = proxy_uri
      if http_proxy.nil?
        Net::HTTP
      else
        Chef::Log.debug("Using #{http_proxy.host}:#{http_proxy.port} for proxy")
        user = http_proxy.user if http_proxy.user
        pass = http_proxy.password if http_proxy.password
        Net::HTTP.Proxy(http_proxy.host, http_proxy.port, user, pass)
      end
    end

    def proxy_uri
      return nil if @api_proxy.nil?
      result = URI.parse(@api_proxy)
      return result unless result.host.nil? || result.host.empty?
      nil
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

      params_arr = []
      params.sort.each { |elem|
        params_arr << elem[0].to_s + '=' + CGI.escape(elem[1].to_s).gsub('+', '%20').gsub(' ','%20')
      }
      data = params_arr.join('&')
      signature = OpenSSL::HMAC.digest('sha1', @secret_key, data.downcase)
      signature = Base64.encode64(signature).chomp
      signature = CGI.escape(signature)

      if @api_url.nil? || @api_url.empty?
        puts "Error: Please specify a valid API URL."
        exit 1
      end

      url = "#{@api_url}?#{data}&signature=#{signature}"
      Chef::Log.debug("URL: #{url}")
      uri = URI.parse(url)

      http = http_client_builder.new(uri.host, uri.port)
 
      if uri.scheme == "https"
        http.use_ssl = true
        # Still need to do some testing on SSL, so will fix this later
        if @no_ssl_verify
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
        else
          http.verify_mode = OpenSSL::SSL::VERIFY_NONE 
        end
      end 
      request = Net::HTTP::Get.new(uri.request_uri)
      response = http.request(request)

      if !response.is_a?(Net::HTTPOK) then
        case response.code
        when "432"
          puts "\n"
          puts "Error #{response.code}: Your account does not have the right to execute this command is locked or the command does not exist."
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
          print "\n"
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

