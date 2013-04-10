#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: KC Braunschweig (<kcbraunschweig@gmail.com>)
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
  class CsServerReboot < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      require 'chef/api_client'
    end

    banner "knife cs server reboot SERVER_NAME [SERVER_NAME ...] (options)"

    def run
      validate_base_options
 
      @name_args.each do |hostname|
        server = connection.get_server(hostname)

        if !server then
          ui.error("Server '#{hostname}' not found")
          next
        end

        object_field = []       
        object_field << ui.color("Name", :yellow, :bold)
        object_field << server['name'].to_s
        object_field << ui.color("Public IP", :yellow, :bold)
        object_field << (connection.get_server_public_ip(server) || '?')
        object_field << ui.color("Service", :yellow, :bold)
        object_field << server['serviceofferingname'].to_s
        object_field << ui.color("Template", :yellow, :bold)
        object_field << server['templatename']
        object_field << ui.color("Domain", :yellow, :bold)
        object_field << server['domain']
        object_field << ui.color("Zone", :yellow, :bold)
        object_field << server['zonename']
        object_field << ui.color("State", :yellow, :bold)
        object_field << server['state']

        puts "\n"
        puts ui.list(object_field, :uneven_columns_across, 2)
        puts "\n"

        ui.confirm("Do you really want to reboot this server")
        print "#{ui.color("Rebooting", :magenta)}"

        connection.reboot_server(hostname)
        puts "\n"
        ui.msg("Rebooted server #{hostname}")
      end

    end

  end
end
