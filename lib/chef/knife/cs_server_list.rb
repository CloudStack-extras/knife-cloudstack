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
           :short => "-U URL",
           :long => "--cloudstack-url URL",
           :description => "The CloudStack endpoint URL",
           :proc => Proc.new { |url| Chef::Config[:knife][:cloudstack_url] = url }

    option :cloudstack_api_key,
           :short => "-A KEY",
           :long => "--cloudstack-api-key KEY",
           :description => "Your CloudStack API key",
           :proc => Proc.new { |key| Chef::Config[:knife][:cloudstack_api_key] = key }

    option :cloudstack_secret_key,
           :short => "-K SECRET",
           :long => "--cloudstack-secret-key SECRET",
           :description => "Your CloudStack secret key",
           :proc => Proc.new { |key| Chef::Config[:knife][:cloudstack_secret_key] = key }

    def run

      $stdout.sync = true

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      server_list = [
          ui.color('Name', :bold),
          ui.color('Public IP', :bold),
          ui.color('Service', :bold),
          ui.color('Template', :bold),
          ui.color('State', :bold)
      ]

      servers = connection.list_servers
      rules = connection.list_port_forwarding_rules

      servers.each do |server|

        name = server['name']
        display_name = server['displayname']
        if display_name && !display_name.empty? && display_name != name
          name << " (#{display_name})"
        end
        server_list << server['name']
        server_list << (connection.get_server_public_ip(server, rules) || '')
        server_list << server['serviceofferingname']
        server_list << server['templatename']
        server_list << server['state']
      end
      puts ui.list(server_list, :columns_across, 5)

    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
