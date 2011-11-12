#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: KC Braunschweig (<kbraunschweig@edmunds.com>)
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
  class CsServerReboot < Chef::Knife

    deps do
      require 'knife-cloudstack/connection'
      require 'chef/api_client'
    end

    banner "knife cs server reboot SERVER_NAME [SERVER_NAME ...] (options)"

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

      @name_args.each do |hostname|
        server = connection.get_server(hostname)

        if !server then
          ui.error("Server '#{hostname}' not found")
          next
        end

        puts "\n"
        msg("Name", server['name'])
        msg("Public IP", connection.get_server_public_ip(server) || '?')
        msg("Service", server['serviceofferingname'])
        msg("Template", server['templatename'])
        msg("Domain", server['domain'])
        msg("Zone", server['zonename'])
        msg("State", server['state'])

        puts "\n"
        ui.confirm("Do you really want to reboot this server")
        print "#{ui.color("Rebooting", :magenta)}"

        connection.reboot_server(hostname)
        puts "\n"
        ui.msg("Rebooted server #{hostname}")
      end

    end

    def connection
      unless @connection
        @connection = CloudstackClient::Connection.new(
            locate_config_value(:cloudstack_url),
            locate_config_value(:cloudstack_api_key),
            locate_config_value(:cloudstack_secret_key)
        )
      end
      @connection
    end

    def msg(label, value)
      if value && !value.empty?
        puts "#{ui.color(label, :cyan)}: #{value}"
      end
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
