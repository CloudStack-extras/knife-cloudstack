#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
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
require 'json'

module KnifeCloudstack
  class CsDomainCreate < Chef::Knife

    deps do
      require 'chef/knife/bootstrap'
      Chef::Knife::Bootstrap.load_deps
      require 'socket'
      require 'net/ssh/multi'
      require 'chef/json_compat'
      require 'knife-cloudstack/connection'
    end

    banner "knife cs domain create [DOMAIN_NAME] (options)"

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

    option :networkdomain,
           :long => "--networkdomain",
           :description => "Network domain for networks in the domain"

    option :parentdomain,
           :long => "--parentdomain PATH",
           :description => "Parent domain path"

    def run

      domainname = @name_args.first
      unless /^[a-zA-Z0-9][_a-zA-Z0-9-]*$/.match domainname then
        ui.error "Invalid domainname, please specify a short domainname.\n"
        exit 1
      end

      $stdout.sync = true

      connection = CloudstackClient::Connection.new(
        locate_config_value(:cloudstack_url),
        locate_config_value(:cloudstack_api_key),
        locate_config_value(:cloudstack_secret_key)
      )

      print "#{ui.color("Creating domain: #{domainname}", :magenta)}\n"
      service = connection.create_domain(
        domainname,
        locate_config_value(:parentdomain),
        locate_config_value(:networkdomain)
      )
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end # class
end
