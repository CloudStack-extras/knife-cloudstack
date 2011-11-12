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
  class CsServiceList < Chef::Knife

    MEGABYTES = 1024 * 1024

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs service list (options)"

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

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      service_list = [
          ui.color('Name', :bold),
          ui.color('Memory', :bold),
          ui.color('CPUs', :bold),
          ui.color('CPU Speed', :bold),
          ui.color('Created', :bold)
      ]

      services = connection.list_service_offerings
      services.each do |s|
        service_list << s['name']
        service_list << (human_memory(s['memory']) || 'Unknown')
        service_list << s['cpunumber'].to_s
        service_list << s['cpuspeed'].to_s + ' Mhz'
        service_list << s['created']
      end
      puts ui.list(service_list, :columns_across, 5)

    end

    def human_memory n
      count = 0
      while  n >= 1024 and count < 2
        n /= 1024.0
        count += 1
      end
      format("%.2f", n) + %w(MB GB TB)[count]
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
