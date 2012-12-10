#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2012 Schuberg Philis.
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
  class CsHostList < Chef::Knife

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs host list (options)"

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

    option :name,
           :long => "--name NAME",
           :description => "Specify hostname to list"

    option :keyword,
           :long => "--service NAME",
           :description => "Specify part of hostname to list"

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

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key),
          locate_config_value(:cloudstack_project),
          locate_config_value(:use_http_ssl)
      )

      access_level = 3
      connection.check_account_access_level access_level

      if locate_config_value(:fields)
        object_list = []
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        object_list = [
          ui.color('Name', :bold),
          ui.color('Address', :bold),
          ui.color('State', :bold),
          ui.color('Type', :bold),
          ui.color('Cluster', :bold),
          ui.color('Pod', :bold),
          ui.color('Zone', :bold),
          ui.color('Resource', :bold)
        ]
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_object(
        "listHosts",
        "host",
        locate_config_value(:filter),
        false,
        locate_config_value(:keyword),
        locate_config_value(:name)
      )

      connection_result.each do |r|
        if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << r['name'].to_s
          object_list << r['ipaddress'].to_s
          object_list << r['state'].to_s
          object_list << r['type'].to_s
          object_list << r['clustername'].to_s
          object_list << r['podname'].to_s
          object_list << r['zonename'].to_s
          object_list << r['resourcestate'].to_s
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
