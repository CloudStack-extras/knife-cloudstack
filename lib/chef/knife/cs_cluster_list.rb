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
  class CsClusterList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBaseList

    banner "knife cs cluster list (options)"

    option :name,
           :long => "--name NAME",
           :description => "Specify cluster name to list"

    option :keyword,
           :long => "--keyword KEY",
           :description => "List by keyword"

    def run
      validate_base_options

      columns = [
        'Name		 :name',
        'Pod		 :podname',
        'Zone		 :zonename',
        'HypervizorType  :hypervisortype',
        'ClusterType	 :clustertype',
        'AllocationState :allocationstate',
        'ManagedState 	 :managedstate'
      ]

      params = { 'command' => "listClusters" }
      params['filter']  = locate_config_value(:filter)  if locate_config_value(:filter)
      params['keyword'] = locate_config_value(:keyword) if locate_config_value(:keyword)
      params['name']    = locate_config_value(:name)    if locate_config_value(:name)
      
      result = connection.list_object(params, "cluster")
      list_object(columns, result)
    end

  end
end
