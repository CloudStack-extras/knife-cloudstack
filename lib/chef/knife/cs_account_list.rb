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
require 'chef/knife/cs_base'

module KnifeCloudstack
  class CsAccountList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs account list (options)"

    option :listall,
           :long => "--listall",
           :description => "List all the accounts",
           :boolean => true

    option :name,
           :long => "--name NAME",
           :description => "Specify account name to list"

    option :keyword,
           :long => "--keyword KEY",
           :description => "List by keyword"

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

      if locate_config_value(:fields)
        object_list = []
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        if locate_config_value(:cloudstack_project) 
          object_list = [
            ui.color('Account', :bold),
            ui.color('Domain', :bold),
            ui.color('Type', :bold),
            ui.color('Role', :bold),
            ui.color('Users', :bold)
          ]
        else
          object_list = [
            ui.color('Name', :bold),
            ui.color('Domain', :bold),
            ui.color('State', :bold),
            ui.color('Type', :bold),
            ui.color('Users', :bold)
          ]
        end
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      if locate_config_value(:cloudstack_project)
        api_command = "listProjectAccounts"
        api_result = "projectaccount"
      else
        api_command = "listAccounts"
        api_result = "account"
      end

      connection_result = connection.list_object(
        api_command,
        api_result,
        locate_config_value(:filter),
        locate_config_value(:listall),
        locate_config_value(:keyword),
        locate_config_value(:name)
      )

      connection_result.each do |r|
       if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
        else
          if locate_config_value(:cloudstack_project)
            object_list << r['account'].to_s
            object_list << r['domain'].to_s
            case r['accounttype']
              when 0 then object_list << "User"
              when 1 then object_list << "Admin"
              when 2 then object_list << "Domain Admin"
              else object_list << "unknown"
            end
            object_list << r['role'].to_s
            object_list << r['user'].count.to_s
          else
            object_list << r['name'].to_s
            object_list << r['domain'].to_s
            object_list << r['state'].to_s
            case r['accounttype']
              when 0 then object_list << "User"
              when 1 then object_list << "Admin"
              when 2 then object_list << "Domain Admin"
              else object_list << "unknown"
            end
            object_list << r['user'].count.to_s
          end
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
