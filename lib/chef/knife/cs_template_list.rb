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

module KnifeCloudstack
  class CsTemplateList < Chef::Knife

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs template list (options)"

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

    option :cloudstack_project,
           :short => "-P PROJECT_NAME",
           :long => '--cloudstack-project PROJECT_NAME',
           :description => "Cloudstack Project in which to create server",
           :proc => Proc.new { |v| Chef::Config[:knife][:cloudstack_project] = v },
           :default => nil

    option :use_http_ssl,
           :long => '--[no-]use-http-ssl',
           :description => 'Support HTTPS',
           :boolean => true,
           :default => true

    option :listall,
           :long => "--listall",
           :description => "List all templates",
           :boolean => true

    option :filter,
           :long => "--filter 'FIELD:NAME'",
           :description => "Specify field and part of name to list"

    option :fields,
           :long => "--fields 'NAME, NAME'",
           :description => "The fields to output, comma-separated"

    option :fieldlist,
           :long => "--fieldlist",
           :description => "The available fields to output/filter",
           :boolean => true

    option :noheader,
           :long => "--noheader",
           :description => "Removes header from output",
           :boolean => true

    option :templatefilter,
           :long => "--templatefilter FILTER",
           :description => "The template search filter. Default is 'featured'",
           :default => "featured"

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
          ui.color('Size', :bold),
          ui.color('Zone', :bold),
          ui.color('Public', :bold),
          ui.color('Created', :bold),
        ]
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_object(
        "listTemplates",
        "template",
        locate_config_value(:filter),
        locate_config_value(:listall),
        nil,
        nil,
        locate_config_value(:templatefilter)
      )

      connection_result.each do |r|

       if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << r['name'].to_s
          object_list << (r['size'] ? human_file_size(r['size']) : 'Unknown')
          object_list << r['zonename'].to_s
          object_list << r['ispublic'].to_s
          object_list << r['created']
        end
      end
      puts ui.list(object_list, :uneven_columns_across, columns)
      connection.show_object_fields(connection_result) if locate_config_value(:fieldlist)
    end

    def human_file_size n
      count = 0
      while  n >= 1024 and count < 4
        n /= 1024.0
        count += 1
      end
      format("%.0f", n) + %w(B KB MB GB TB)[count]
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
