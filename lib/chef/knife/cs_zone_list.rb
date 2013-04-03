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

require 'chef/knife'
require 'chef/knife/cs_base'
require 'chef/knife/cs_baselist'

module KnifeCloudstack
  class CsZoneList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase
    include Chef::Knife::KnifeCloudstackBaseList

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs zone list (options)"

    option :keyword,
           :long => "--keyword KEY",
           :description => "List by keyword"

    option :index,
           :long => "--index",
           :description => "Add index numbers to the output",
           :boolean => true

    def run
      validate_base_options

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key),
          locate_config_value(:cloudstack_project),
          locate_config_value(:cloudstack_account),
          locate_config_value(:use_http_ssl)
      )
 
      object_list = []
      object_list << ui.color('Index', :bold) if locate_config_value(:index)

      if locate_config_value(:fields)
        object_list = []
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        [
 	  ui.color('Name', :bold),
          ui.color('Network Type', :bold),
          ui.color('Security Groups', :bold)
        ].each { |field| object_list << field }
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_object(
        "listZones",
        "zone", 
        locate_config_value(:filter),
	false,
        locate_config_value(:keyword)
      )

      index_num = 0
      connection_result.each do |r|
        if locate_config_value(:index)
          index_num += 1
          object_list << index_num.to_s
        end

        if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((r[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << r['name'].to_s
          object_list << r['networktype'].to_s
          object_list << r['securitygroupsenabled'].to_s
        end
      end
      puts ui.list(object_list, :uneven_columns_across, columns)
      list_object_fields(connection_result) if locate_config_value(:fieldlist)
    end

  end
end
