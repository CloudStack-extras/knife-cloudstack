#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
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

module KnifeCloudstack
  class CsServerList < Chef::Knife

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs server list (options)"

    option :cloudstack_url,
           :short => "-s URL",
           :long => "--server-url URL",
           :description => "Your CloudStack endpoint URL",
           :proc => Proc.new { |url| Chef::Config[:knife][:cloudstack_url] = url }

    option :cloudstack_api_key,
           :short => "-k KEY",
           :long => "--key KEY",
           :description => "Your CloudStack API key",
           :proc => Proc.new { |key| Chef::Config[:knife][:cloudstack_api_key] = key }

    option :cloudstack_secret_key,
           :short => "-K SECRET",
           :long => "--secret SECRET",
           :description => "Your CloudStack secret key",
           :proc => Proc.new { |key| Chef::Config[:knife][:cloudstack_secret_key] = key }

#    option :cloudstack_project,
#           :short => "-P PROJECT_NAME",
#           :long => '--cloudstack-project PROJECT_NAME',
#           :description => "Cloudstack Project in which to create server",
#           :proc => Proc.new { |v| Chef::Config[:knife][:cloudstack_project] = v },
#           :default => nil

    option :use_http_ssl,
           :long => '--[no-]use-http-ssl',
           :description => 'Support HTTPS',
           :boolean => true,
           :default => true     

    option :listall,
           :long => "--listall",
           :description => "List all the accounts",
           :boolean => true

    option :name,
           :long => "--name NAME",
           :description => "Specify hostname to list"

    option :keyword,
           :long => "--instance NAME",
           :description => "Specify part of instancename to list"

#    option :account,
#           :long => "--account NAME",
#           :description => "Specify part of accountname to list"
#
#    option :domain,
#           :long => "--domain NAME",
#           :description => "Specify part of domainname to list"

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
          ui.color('Instance', :bold),
          ui.color('Name', :bold),
          ui.color('Public IP', :bold),
          ui.color('Service', :bold),
          ui.color('Template', :bold),
          ui.color('State', :bold),
          ui.color('Hypervisor', :bold)
        ]
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_servers(
        locate_config_value(:listall),
        locate_config_value(:name),
        locate_config_value(:keyword),
        locate_config_value(:filter)
      )

      rules = connection.list_port_forwarding_rules

      connection_result.each do |result|
        name = result['name']
        display_name = result['displayname']
        if display_name && !display_name.empty? && display_name != name
          name << " (#{display_name})"
        end

        if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((result[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << result['instancename']
          object_list << result['name']
          object_list << (connection.get_server_public_ip(result, rules) || '')
          object_list << result['serviceofferingname']
          object_list << result['templatename']
          object_list << result['state']
          object_list << (result['hostname'] || 'N/A')
        end
      end
      puts ui.list(object_list, :uneven_columns_across, columns)
      connection.show_object_fields(connection_result) if locate_config_value(:fieldlist)
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
