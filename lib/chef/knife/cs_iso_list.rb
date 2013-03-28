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
  class CsIsoList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs iso list (options)"

    option :listall,
           :long => "--listall",
           :description => "List all iso's",
           :boolean => true

    option :name,
           :long => "--name NAME",
           :description => "Specify iso name to list"

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

      object_list = []
      if locate_config_value(:fields)
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        object_list << ui.color('Name', :bold)
        object_list << ui.color('Account', :bold) unless locate_config_value(:cloudstack_project)
        object_list << ui.color('Domain', :bold)
        object_list << ui.color('Public', :bold)
        object_list << ui.color('Size', :bold)
        object_list << ui.color('OS', :bold)
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_object(
        "listIsos",
        "iso",
        locate_config_value(:filter),
        locate_config_value(:listall),
        locate_config_value(:keyword),
        locate_config_value(:name)
      )

      connection_result.each do |r|
       if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << r['name'].to_s
          object_list << (r['account'] ? r['account'].to_s : 'N/A') unless locate_config_value(:cloudstack_project)
          object_list << r['domain'].to_s
          object_list << r['ispublic'].to_s
          object_list << (r['size'] ? human_file_size(r['size']) : 'Unknown')
          object_list << (r['ostypename'] ? r['ostypename'].to_s : 'N/A')
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
