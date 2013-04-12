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
  class CsTemplateList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase
    include Chef::Knife::KnifeCloudstackBaseList

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs template list (options)"

    option :listall,
           :long => "--listall",
           :description => "List all templates",
           :boolean => true

    option :index,
           :long => "--index",
           :description => "Add index numbers to the output",
           :boolean => true

    option :templatefilter,
           :long => "--templatefilter FILTER",
           :description => "Default: 'featured'. Options: 'self','self-executable','executable','community'",
           :default => "featured"

    def run
      validate_base_options

      object_list = []
      object_list << ui.color('Index', :bold) if locate_config_value(:index)

      if locate_config_value(:fields)
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
       [ 
          ui.color('Name', :bold),
          ui.color('Size', :bold),
          ui.color('Zone', :bold),
          ui.color('Public', :bold),
          ui.color('Created', :bold)
        ].each { |field| object_list << field }
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

      output_format(connection_result)

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
          object_list << (r['size'] ? human_file_size(r['size']) : 'Unknown')
          object_list << r['zonename'].to_s
          object_list << r['ispublic'].to_s
          object_list << r['created']
        end
      end
      puts ui.list(object_list, :uneven_columns_across, columns)
      list_object_fields(connection_result) if locate_config_value(:fieldlist)
    end

    def human_file_size n
      count = 0
      while  n >= 1024 and count < 4
        n /= 1024.0
        count += 1
      end
      format("%.0f", n) + %w(B KB MB GB TB)[count]
    end

  end
end
