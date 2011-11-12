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
  class CsTemplateList < Chef::Knife

    MEGABYTES = 1024 * 1024

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs template list (options)"

    option :filter,
           :short => "-L FILTER",
           :long => "--filter FILTER",
           :description => "The template search filter. Default is 'featured'",
           :default => "featured"

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

      template_list = [
          ui.color('Name', :bold),
          ui.color('Size', :bold),
          ui.color('Zone', :bold),
          ui.color('Public', :bold),
          ui.color('Created', :bold),
      ]

      filter = config['filter']
      templates = connection.list_templates(filter)
      templates.each do |t|
        template_list << t['name']
        template_list << (human_file_size(t['size']) || 'Unknown')
        template_list << t['zonename']
        template_list << t['ispublic'].to_s
        template_list << t['created']
      end
      puts ui.list(template_list, :columns_across, 5)

    end

    def human_file_size n
      count = 0
      while  n >= 1024 and count < 4
        n /= 1024.0
        count += 1
      end
      format("%.2f", n) + %w(B KB MB GB TB)[count]
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
