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

require 'chef/knife'
require 'chef/knife/cs_base'

module KnifeCloudstack
  class CsServerDelete < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      require 'chef/api_client'
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

        object_field = []
        object_field << ui.color("Name:", :cyan)
        object_field << server['name'].to_s
        object_field << ui.color("Public IP:", :cyan)
        object_field << (connection.get_server_public_ip(server) || '?')
        object_field << ui.color("Service:", :cyan)
        object_field << server['serviceofferingname'].to_s
        object_field << ui.color("Template:", :cyan)
        object_field << server['templatename']
        object_field << ui.color("Domain:", :cyan)
        object_field << server['domain']
        object_field << ui.color("Zone:", :cyan)
        object_field << server['zonename']
        object_field << ui.color("State:", :cyan)
        object_field << server['state']

        puts "\n"
        puts ui.list(object_field, :uneven_columns_across, 2)
        puts "\n"

        ui.confirm("Do you really want to delete this server")

        print "#{ui.color("Waiting for deletion", :magenta)}"
        disassociate_virtual_ip_address server
        connection.delete_server hostname
        puts "\n"
        ui.msg("Deleted server #{hostname}")

        # delete chef client and node
        node_name = connection.get_server_fqdn server
        ui.confirm("Do you want to delete the chef node and client '#{node_name}")
        delete_node node_name
        delete_client node_name
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
