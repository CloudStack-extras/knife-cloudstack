#
# Author:: John E. Vincent (<lusis.org+github.com@gmail.com>)
# Copyright:: Copyright (c) 2013 John E. Vincent
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
  class CsServerRemoveNic < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase
    include Chef::Knife::KnifeCloudstackBaseList

    deps do
      require 'knife-cloudstack/connection'
      require 'chef/knife'
      Chef::Knife.load_deps
    end

    banner "knife cs server remove nic SERVERID NICID"


    def run
      validate_base_options

      @server_id, @nic_id = name_args

      if @server_id.nil? || @nic_id.nil?
        show_usage
        ui.fatal("You must provide both a nic id and a server id")
        exit(1)
      end


      object_list = []
      if locate_config_value(:fields)
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        object_list << ui.color('Server', :bold)
        object_list << ui.color('Network', :bold)
        object_list << ui.color('Type', :bold)
        object_list << ui.color('Default', :bold)
        object_list << ui.color('Address', :bold)
        object_list << ui.color('Gateway', :bold)
        object_list << ui.color('Netmask', :bold)
        object_list << ui.color('ID', :bold)
      end

      columns = object_list.count

      connection_result = connection.remove_nic_from_vm(
        @nic_id,
        @server_id
      )

      output_format(connection_result)

      object_list << connection_result['name']
      object_list << ''
      object_list << ''
      object_list << ''
      object_list << ''
      object_list << ''
      object_list << ''
      object_list << ''
      if connection_result['nic']
        connection_result['nic'].each do |r|
            if locate_config_value(:fields)
              locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
            else
              object_list << ''
              object_list << r['networkname'].to_s
              object_list << r['type'].to_s
              object_list << (r['isdefault'] ? r['isdefault'].to_s : 'false')
              object_list << (r['ipaddress'] || '')
              object_list << (r['gateway'] || '')
              object_list << (r['netmask'] || '')
              object_list << (r['networkid'] || '')
            end
        end
        puts ui.list(object_list, :uneven_columns_across, columns)
        list_object_fields(connection_result) if locate_config_value(:fieldlist)
      else
        ui.error("No nics returned in response")
      end
    end
  end
end
