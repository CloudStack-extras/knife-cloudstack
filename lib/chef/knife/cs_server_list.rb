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
require 'chef/knife/cs_baselist'

module KnifeCloudstack
  class CsServerList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase
    include Chef::Knife::KnifeCloudstackBaseList

    deps do
      require 'knife-cloudstack/connection'
    end

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
           :description => "start or stop the instances in your result"

    def run

      $stdout.sync = true

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key),
          locate_config_value(:cloudstack_project),
          locate_config_value(:use_http_ssl)
      )

      if locate_config_value(:fields)
        object_list = []  
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        object_list = [
          ui.color('Name', :bold),
          ui.color('Public IP', :bold),
          ui.color('Service', :bold),
          ui.color('Template', :bold),
          ui.color('State', :bold),
          ui.color('Instance', :bold),
          ui.color('Hypervisor', :bold)
        ]
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_object(
        "listVirtualMachines",
        "virtualmachine",
        locate_config_value(:filter),
        locate_config_value(:listall),
        locate_config_value(:keyword),
        locate_config_value(:name)
      )

      rules = connection.list_port_forwarding_rules

      connection_result.each do |r|
        name = r['name']
        display_name = r['displayname']
        if display_name && !display_name.empty? && display_name != name
          name << " (#{display_name})"
        end

        if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << r['name']
          object_list << (connection.get_server_public_ip(r, rules) || '')
          object_list << r['serviceofferingname']
          object_list << r['templatename']
          object_list << r['state']
          object_list << (r['instancename'] || 'N/A')
          object_list << (r['hostname'] || 'N/A')
        end
      end

      puts ui.list(object_list, :uneven_columns_across, columns)
      list_object_fields(connection_result) if locate_config_value(:fieldlist)

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
      object_fields = [
        ui.color('Key', :bold),
        ui.color('Value', :bold)
      ]

      object_fields << ui.color("Name", :yellow, :bold)
      object_fields << s['name'].to_s
      object_fields << ui.color("Public IP", :yellow, :bold)
      object_fields << (connection.get_server_public_ip(s, rules) || '')
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

    def msg(label, value)
      if value && !value.empty?
        puts "#{ui.color(label, :cyan)}: #{value}"
      end
    end


  end
end
