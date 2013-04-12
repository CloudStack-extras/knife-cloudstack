#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2011 Edmunds, Inc.
# Copyright:: Copyright (c) 2013 Sander Botman.
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
require 'chef/knife/cs_base'
require 'chef/knife/cs_baselist'

module KnifeCloudstack
  class CsNetworkList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase
    include Chef::Knife::KnifeCloudstackBaseList

    deps do
      require 'knife-cloudstack/connection'
      require 'chef/knife'
      Chef::Knife.load_deps
    end

    banner "knife cs network list (options)"

    option :listall,
           :long => "--listall",
           :description => "List all networks",
           :boolean => true

    option :keyword,
           :long => "--keyword KEY",
           :description => "List by keyword"

    def run
      validate_base_options

      object_list = []
      if locate_config_value(:fields)
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        object_list << ui.color('Name', :bold)
        object_list << ui.color('Type', :bold)
        object_list << ui.color('Default', :bold)
        object_list << ui.color('Shared', :bold)
        object_list << ui.color('Gateway', :bold)
        object_list << ui.color('Netmask', :bold)
        object_list << ui.color('Account', :bold) unless locate_config_value(:cloudstack_project)
        object_list << ui.color('Domain', :bold)
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_object(
        "listNetworks",
        "network",
        locate_config_value(:filter),
        locate_config_value(:listall),
        locate_config_value(:keyword)
      )

      connection_result.each do |r|
        if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << r['name'].to_s
          object_list << r['type'].to_s
          object_list << (r['isdefault'] ? r['isdefault'].to_s : 'false')
          object_list << (r['isshared'] ? r['isshared'].to_s : 'false')
          object_list << (r['gateway'] || '')
          object_list << (r['netmask'] || '')
          object_list << (r['account'] || '') unless locate_config_value(:cloudstack_project)
          object_list << (r['domain'] || '')
        end
      end
      puts ui.list(object_list, :uneven_columns_across, columns)
      list_object_fields(connection_result) if locate_config_value(:fieldlist)
    end
  end
end
