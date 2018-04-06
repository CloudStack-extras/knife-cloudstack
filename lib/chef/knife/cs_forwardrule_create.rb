#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Author:: Robbert-Jan Sperna Weiland (<rspernaweiland@schubergphilis.com>)
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
  class CsForwardruleCreate < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      Chef::Knife.load_deps
    end

    banner "knife cs forwardrule create hostname 8080:8090:TCP (options)"

    option :openfirewall,
           :long => "--openfirewall",
           :description => "Add rule also to firewall",
           :boolean => true

    option :syncrequest,
           :long => "--sync",
           :description => "Execute command as sync request",
           :boolean => true

    option :vrip,
           :long => "--vrip PUBLIC_ROUTER_IP",
           :description => "Public IP associated with virtual router to expose the external port on. Use this to indicate the server has an internal IP that needs to be exposed on the router's public IP."

    def run

      hostname = @name_args.shift
      unless /^[a-zA-Z0-9][a-zA-Z0-9-]*$/.match hostname then
       ui.error "Invalid hostname. Please specify a short hostname, not an fqdn (e.g. 'myhost' instead of 'myhost.domain.com')."
        exit 1
      end

      params = {}
      locate_config_value(:openfirewall) ? params['openfirewall'] = 'true' : params['openfirewall'] = 'false'

      # Lookup all server objects.
      params_for_list_object = {  'command' => 'listVirtualMachines' }
      connection_result = connection.list_object(params_for_list_object, "virtualmachine")

      # Lookup the hostname in the connection result
      server = {}
      connection_result.map { |n| server = n if n['name'].upcase == hostname.upcase }
     
      if server['name'].nil?
        ui.error "Cannot find hostname: #{hostname}."
        exit 1
      end

      if locate_config_value(:vrip)
        Chef::Log.debug("Forwarding rule for VPC.")
        server['nic'].each do |nic|
          params['vmguestip'] = nic['ipaddress']
        end
        ip_address = {}
        ip_address['ipaddress'] = config[:vrip]
      else
        Chef::Log.debug("Forwarding rule for public IP on server")
        server_address = connection.get_server_public_ip(server)
        ip_address = connection.get_public_ip_address(server_address)
  
        if ip_address.nil? || ip_address['id'].nil?
          ui.error "Cannot find public ip address for hostname: #{hostname}."
          exit 1
        end
      end

      @name_args.each do |rule|
        create_port_forwarding_rule(ip_address, server['id'], rule, connection, params)
      end
    end
 
    def create_port_forwarding_rule(ip_address, server_id, rule, connection, other_params)
      args = rule.split(':')
      public_port = args[0]
      private_port = args[1] || args[0]
      protocol = args[2] || "TCP"

      params = {
        'ipaddressId' => ip_address['id'],
        'protocol' => protocol
      }

      if other_params['vmguestip']
        # VPC based network
        # Find networkid associated with ip_address
        other_params['networkid'] = connection.get_networkid_from_ip_address(ip_address['ipaddress'])

        # Find id of public router IP
        public_ip = connection.get_public_ip_address(ip_address['ipaddress'])
        params['ipaddressId'] = public_ip['id']
        
        other_params['command'] = 'createPortForwardingRule'
        other_params['privatePort'] = private_port
        other_params['privateEndPort'] = private_port
        other_params['publicPort'] = public_port
        other_params['publicEndPort'] = public_port
        other_params['virtualMachineId'] = server_id

        Chef::Log.debug("Creating port Forwarding Rule for router ip 
          #{ip_address['ipaddress']} with protocol: #{protocol}, public port: #{public_port}")
      elsif ip_address['isstaticnat'] == 'true'
        other_params['command'] = 'createIpForwardingRule'
        other_params['startport'] = public_port
        other_params['endport'] = public_port
        Chef::Log.debug("Creating IP Forwarding Rule for
          #{ip_address['ipaddress']} with protocol: #{protocol}, public port: #{public_port}")
      else
        other_params['command'] = 'createPortForwardingRule'
        other_params['privatePort'] = private_port
        other_params['publicPort'] = public_port
        other_params['virtualMachineId'] = server_id
        Chef::Log.debug("Creating Port Forwarding Rule for #{ip_address['id']} with protocol: #{protocol},
          public port: #{public_port} and private port: #{private_port} and server: #{server_id}")
      end
      locate_config_value(:syncrequest) ? result = connection.send_request(params.merge(other_params)) : result = connection.send_async_request(params.merge(other_params))
      Chef::Log.debug("AsyncJobResult: #{result}")
    end
  end
end
