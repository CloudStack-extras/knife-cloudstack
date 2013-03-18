#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Revised:: 20121210 Sander Botman (<sbotman@schubergphilis.com>)
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

require 'chef/knife'
require 'chef/knife/cs_base'

module KnifeCloudstack
  class CsServerList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

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

    option :filter,
           :long => "--filter 'FIELD:NAME'",
           :description => "Specify field and part of name to list"

    option :fields,
           :long => "--fields 'NAME, NAME'",
           :description => "The fields to output, comma-separated"
    
    option :fieldlist,
           :long => "--fieldlist",
           :description => "The available fields to output, comma-separated",
           :boolean => true

    option :noheader,
           :long => "--noheader",
           :description => "Removes header from output",
           :boolean => true

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
      connection.show_object_fields(connection_result) if locate_config_value(:fieldlist)

      if locate_config_value(:action)
        case locate_config_value(:action).downcase
          when "start" then connection.server_action("startVirtualMachine", "virtualmachine", connection_result, locate_config_value(:yes))
          when "stop" then connection.server_action("stopVirtualMachine", "virtualmachine", connection_result, locate_config_value(:yes))
        end
      end
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
