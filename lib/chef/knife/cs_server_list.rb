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
require 'chef/knife/cs_baselist'

module KnifeCloudstack
  class CsServerList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBaseList

    banner "knife cs server list (options)"

    option :listall,
           :long => "--listall",
           :description => "List all the accounts",
           :boolean => true

    option :name,
           :long => "--name NAME",
           :description => "Specify hostname to list"

    option :keyword,
           :long => "--keyword NAME",
           :description => "Specify part of instancename to list"

    option :action,
           :short => "-a ACTION",
           :long => "--action ACTION",
           :description => "start, stop or destroy the instances in your result"
           
    option :public_ip,
           :long => "--[no-]public-ip",
           :description => "Show or don't show the public IP for server in your result",
           :boolean => true,
           :default => true

    def run
      validate_base_options
 
      columns = [
        'Name       :name',
        'Public IP  :ipaddress',
        'Service    :serviceofferingname',
        'Template   :templatename',
        'State      :state',
        'Instance   :instancename',
        'Hypervisor :hostname'
      ]

      params = { 'command' => "listVirtualMachines" }
      params['filter']  = locate_config_value(:filter)  if locate_config_value(:filter)
      params['listall'] = locate_config_value(:listall) if locate_config_value(:listall)
      params['keyword'] = locate_config_value(:keyword) if locate_config_value(:keyword)
      params['name']    = locate_config_value(:name)    if locate_config_value(:name)
      
      ##
      # Get the public IP address if possible, except when the option --no-public-ip is given.

      rules       = connection.list_port_forwarding_rules(nil, true)
      public_list = connection.list_public_ip_addresses(true)
      result      = connection.list_object(params, "virtualmachine")
      result.each do |n| 
        public_ip  = connection.get_server_public_ip(n, rules, public_list) if locate_config_value(:public_ip)
        private_ip = n['nic'].select { |k| k['isdefault'] }       
        public_ip ? n['ipaddress'] = public_ip : n['ipaddress'] = private_ip['ipaddress'] || "N/A" 
      end

      list_object(columns, result)
      
      ## 
      # Executing actions against the list results that are returned.

      if locate_config_value(:action)
        connection_result.each do |r|
          hostname = r['name'] 
          case locate_config_value(:action).downcase
          when "start" then
            show_object_details(r, connection, rules)
            result = confirm_action("Do you really want to start this server ")
            if result then 
              print "#{ui.color("Waiting for startup", :magenta)}"
	      connection.start_server(hostname)
              puts "\n"
              ui.msg("Started server #{hostname}")
            end 
          when "stop" then 
            show_object_details(r, connection, rules)
            result = confirm_action("Do you really want to stop this server ")
            if result then 
              print "#{ui.color("Waiting for shutdown", :magenta)}"
              connection.stop_server(hostname)
              puts "\n"
              ui.msg("Shutdown server #{hostname}")
            end 
          when "destroy" then 
            show_object_details(r, connection, rules)
            result = confirm_action("Do you really want to destroy this server ")
            if result then
              print "#{ui.color("Waiting for demolition", :magenta)}"
              connection.delete_server(hostname)
              puts "\n"
              ui.msg("Destroyed server #{hostname}")
            end
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

  end
end
