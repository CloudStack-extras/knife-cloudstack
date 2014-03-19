#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2011 Edmunds, Inc.
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
  class CsServerDelete < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      require 'chef/api_client'
      require 'chef/knife'
      Chef::Knife.load_deps
    end

    banner "knife cs server delete SERVER_NAME [SERVER_NAME ...] (options)"

    def run
      validate_base_options

      @name_args.each do |hostname|
        server = connection.get_server(hostname)

        if !server then
          ui.error("Server '#{hostname}' not found")
          next
        end

        if server['state'] == 'Destroyed' then
          ui.warn("Server '#{hostname}' already destroyed")
          next
        end

        rules = connection.list_port_forwarding_rules

        show_object_details(server, connection, rules)

        result = confirm_action("Do you really want to delete this server")
        if result
          print "#{ui.color("Waiting for deletion", :magenta)}"
          disassociate_virtual_ip_address server
          connection.delete_server(hostname, false)
          puts "\n"
          ui.msg("Deleted server #{hostname}")

          # delete chef client and node
          node_name = connection.get_server_fqdn server
          delete_chef = confirm_action("Do you want to delete the chef node and client '#{node_name}")
          if delete_chef
            delete_node node_name
            delete_client node_name
          end

        end
      end
    end

    def show_object_details(s, connection, rules)
      return if locate_config_value(:yes)
      
      object_fields = []
      object_fields << ui.color("Name:", :cyan)
      object_fields << s['name'].to_s
      object_fields << ui.color("Public IP:", :cyan)
      object_fields << (connection.get_server_public_ip(s, rules) || '')
      object_fields << ui.color("Service:", :cyan)
      object_fields << s['serviceofferingname'].to_s
      object_fields << ui.color("Template:", :cyan)
      object_fields << s['templatename']
      object_fields << ui.color("Domain:", :cyan)
      object_fields << s['domain']
      object_fields << ui.color("Zone:", :cyan)
      object_fields << s['zonename']
      object_fields << ui.color("State:", :cyan)
      object_fields << s['state']

      puts "\n"
      puts ui.list(object_fields, :uneven_columns_across, 2)
      puts "\n"
    end

    def confirm_action(question)
      return true if locate_config_value(:yes)
      result = ui.ask_question(question, :default => "Y" )
      if result == "Y" || result == "y" then
        return true
      else
        return false
      end
    end

    def disassociate_virtual_ip_address(server)
      ip_addr = connection.get_server_public_ip(server)
      return unless ip_addr
      ip_addr_info = connection.get_public_ip_address(ip_addr)
      #Check if Public IP has been allocated and is not Source NAT
      if ip_addr_info
        if not ip_addr_info['issourcenat']
          connection.disassociate_ip_address(ip_addr_info['id'])
        end
      end
    end

    def delete_client(name)
      begin
        client = Chef::ApiClient.load(name)
      rescue Net::HTTPServerException
        return
      end

      client.destroy
      ui.msg "Deleted client #{name}"
    end

    def delete_node(name)
      begin
        node = Chef::Node.load(name)
      rescue Net::HTTPServerException
        return
      end

      node.destroy
      ui.msg "Deleted node #{name}"
    end

  end
end
