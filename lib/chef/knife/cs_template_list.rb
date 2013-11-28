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
require 'chef/knife/cs_baselist'

module KnifeCloudstack
  class CsTemplateList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBaseList

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

      columns = [
        'Name    :name',
        'Size    :size',
        'Zone    :zonename',
        'Public  :ispublic',
        'Created :created'
      ]

      params = { 'command' => "listTemplates" }
      params['filter']  = locate_config_value(:filter)  if locate_config_value(:filter)
      params['listall'] = locate_config_value(:listall) if locate_config_value(:listall)
      params['keyword'] = locate_config_value(:keyword) if locate_config_value(:keyword)
      params['name']    = locate_config_value(:name)    if locate_config_value(:name)

      if ['featured','self','self-executable','executable','community'].include?(locate_config_value(:templatefilter)) 
        params['templatefilter'] = locate_config_value(:templatefilter)
      else
        params['templatefilter'] = 'featured'
      end 

      result = connection.list_object(params, "template")

      result.each do |r|
        r['size'] = human_file_size(r['size']) if r['size']
      end

      list_object(columns, result)
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
