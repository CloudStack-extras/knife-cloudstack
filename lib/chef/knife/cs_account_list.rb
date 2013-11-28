#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
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
  class CsAccountList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBaseList

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

    def run
      validate_base_options

      if locate_config_value(:cloudstack_project)
        columns = [
          'Account :account',
          'Domain  :domain',
          'Type    :accounttype',
          'Role    :role',
          'Users   :user'
        ]
        params = { 'command' => "listProjectAccounts" }
      else
        columns = [
          'Name     :name',
          'Domain   :domain',
          'State    :state',
          'Type     :accounttype',
          'Users    :user'
        ]
        params = { 'command' => "listAccounts" }
      end

      params['filter']  = locate_config_value(:filter)  if locate_config_value(:filter)
      params['listall'] = locate_config_value(:listall) if locate_config_value(:listall)
      params['keyword'] = locate_config_value(:keyword) if locate_config_value(:keyword)
      params['name']    = locate_config_value(:name)    if locate_config_value(:name)
      
      if locate_config_value(:cloudstack_project)
        result = connection.list_object(params, "projectaccount") 
      else
        result = connection.list_object(params, "account")
      end

      result.each do |r|
        r['accounttype'] = 'User' if r['accounttype'] == 0
        r['accounttype'] = 'Admin' if r['accounttype'] == 1
        r['accounttype'] = 'Domain Admin' if r['accounttype'] == 2
        r['user'] = r['user'].count if r['user']
      end

      list_object(columns, result)
    end

  end
end
