#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2013 Sander Botman.
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

require 'chef/knife/cs_base'

module KnifeCloudstack
  class CsFirewallruleCreate < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      Chef::Knife.load_deps
    end

    banner "knife cs firewallrule create hostname 8080:8090:TCP:10.0.0.0/24"

    option :syncrequest,
           :long => "--sync",
           :description => "Execute command as sync request",
           :boolean => true

    def run

      hostname = @name_args.shift
      unless /^[a-zA-Z0-9][a-zA-Z0-9-]*$/.match hostname then
       ui.error "Invalid hostname. Please specify a short hostname, not an fqdn (e.g. 'myhost' instead of 'myhost.domain.com')."
        exit 1
      end

      params = {}
      locate_config_value(:openfirewall) ? params['openfirewall'] = 'true' : params['openfirewall'] = 'false'

      # Lookup all server objects.
      connection_result = connection.list_object(
        "listVirtualMachines",
        "virtualmachine"
      )

      # Lookup the hostname in the connection result
      server = {}
      connection_result.map { |n| server = n if n['name'].upcase == hostname.upcase }
     
      if server['name'].nil?
        ui.error "Cannot find hostname: #{hostname}."
        exit 1
      end

      # Lookup the public ip address of the server
      server_public_address = connection.get_server_public_ip(server)
      ip_address = connection.get_public_ip_address(server_public_address)

      if ip_address.nil? || ip_address['id'].nil?
        ui.error "Cannot find public ip address for hostname: #{hostname}."
        exit 1
      end
 
      @name_args.each do |rule|
        create_port_forwarding_rule(ip_address, server['id'], rule, connection, params)
      end

    end
 
    def create_port_forwarding_rule(ip_address, server_id, rule, connection, other_params)
      args = rule.split(':')
      startport = args[0]
      endport   = args[1] || args[0]
      protocol  = args[2] || "TCP"
      cidrlist  = args[3] || "0.0.0.0/0"      

      # Required parameters
      params = {
        'command' => 'createFirewallRule',
        'ipaddressId' => ip_address['id'],
        'protocol' => protocol
      }

      # Optional parameters
      opt_params = {
        'startport' => startport,
        'endport' => endport,
        'cidrlist' => cidrlist
      }
  
      params.merge!(opt_params)
 
      Chef::Log.debug("Creating Firewall Rule for
        #{ip_address['ipaddress']} with protocol: #{protocol}, start: #{startport} end: #{endport} cidr: #{cidrlist}")

      if locate_config_value(:syncrequest) 
        result = connection.send_request(params)
        Chef::Log.debug("JobResult: #{result}")
      else
        result = connection.send_async_request(params)
        Chef::Log.debug("AsyncJobResult: #{result}")
      end
    end

  end
end
