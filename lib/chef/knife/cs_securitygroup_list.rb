# 
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Author:: Sebastien Goasguen (<runseb@gmail.com>)
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
  class CsSecuritygroupList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBaseList
    
    banner "knife cs securitygroup list (options)"

    option :name,
           :long => "--name NAME",
           :description => "Specify security group to list"

    option :keyword,
           :long => "--keyword NAME",
           :description => "Specify part of servicename to list"

    def run
      validate_base_options

      columns = [
        'Name        :name',
        'Description :description',
        'Account     :account'
      ]

      params = { 'command' => "listSecurityGroups" }
      params['filter']  = locate_config_value(:filter)  if locate_config_value(:filter)
      params['keyword'] = locate_config_value(:keyword) if locate_config_value(:keyword)
      params['name']    = locate_config_value(:name)    if locate_config_value(:name)
      
      result = connection.list_object(params, "securitygroup")
      list_object(columns, result)
    end

  end
end
