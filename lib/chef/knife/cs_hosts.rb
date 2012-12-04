#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: KC Braunschweig (<kcbraunschweig@gmail.com>)
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
  class CsHosts < Chef::Knife

    MEGABYTES = 1024 * 1024

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs hosts"

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

    option :listall,
           :long => "--listall",
           :description => "List all the accounts",
           :boolean => true

    option :name,
           :long => "--name NAME",
           :description => "Specify machine name to list"

    option :keyword,
           :long => "--keyword KEY",
           :description => "List by keyword"

    option :account,
           :long => "--account NAME",
           :description => "Show machines that belong to account name"

    option :domain,
           :long => "--domain NAME",
           :description => "Show machines that belong to domain"

    def run

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      host_list = [
          ui.color('Instance', :bold),
          ui.color('IP', :bold),
          ui.color('Host', :bold)
      ]

      host_list << ui.color('Domain', :bold) if locate_config_value(:domain)
      host_list << ui.color('Account', :bold) if locate_config_value(:account)
      
      columns = host_list.count

      servers = connection.list_servers(
        locate_config_value(:listall),
        locate_config_value(:name),
        locate_config_value(:account),
        locate_config_value(:keyword),
        locate_config_value(:domain)
      )

      unless servers 
        puts "Cannot find any hosts"
        exit 1
      end

      pf_rules = connection.list_port_forwarding_rules
      servers.each do |s|
        host_list << s['instancename'].to_s 
        host_list << (connection.get_server_public_ip(s, pf_rules) || '#')
        host_list << (s['name'] || '')
        host_list << s['domain'].to_s if locate_config_value(:domain)
        host_list << s['account'].to_s if locate_config_value(:account)
      end
      puts ui.list(host_list, :columns_across, columns)

    end


    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
