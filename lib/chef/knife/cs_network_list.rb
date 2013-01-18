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
require 'knife-cloudstack/helpers'

module KnifeCloudstack
  class CsNetworkList < Chef::Knife

    include Helpers

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs network list (options)"

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

    option :use_http_ssl,
           :long => '--[no-]use-http-ssl',
           :description => 'Support HTTPS',
           :boolean => true,
           :default => true     

    def run

      network_list = [
          ui.color('Name', :bold),
          ui.color('Type', :bold),
          ui.color('Default', :bold),
          ui.color('Shared', :bold),
          ui.color('Gateway', :bold),
          ui.color('Netmask', :bold)
      ]

      networks = connection.list_networks
      networks.each do |n|
        network_list << n['name']
        network_list << n['type']
        network_list << n['isdefault'].to_s
        network_list << n['isshared'].to_s
        network_list << (n['gateway'] || '')
        network_list << (n['netmask'] || '')
      end
      puts ui.list(network_list, :columns_across, 6)

    end

  end
end
