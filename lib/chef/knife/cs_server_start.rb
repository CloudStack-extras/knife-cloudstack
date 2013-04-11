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
  class CsServerStart < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      require 'chef/api_client'
    end

    banner "knife cs server start SERVER_NAME [SERVER_NAME ...] (options)"

    def run
    validate_base_options

      @name_args.each do |hostname|
        server = connection.get_server(hostname)

        if !server then
          ui.error("Server '#{hostname}' not found")
          next
        end

        rules = connection.list_port_forwarding_rules
       
        show_object_details(server, connection, rules)

        result = confirm_action("Do you really want to start this server")
        if result
          print "#{ui.color("Waiting for startup", :magenta)}"
          connection.start_server(hostname)
          puts "\n"
          ui.msg("Started server #{hostname}")
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

  end
end
