#
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
  class CsKeypairList < Chef::Knife

    include Chef::Knife::KnifeCloudstackBaseList

    banner "knife cs keypair list (options)"

    def run
      validate_base_options
  
      columns = [
        'Name        :name',
        'Fingerprint :fingerprint'
      ]

      params = { 'command' => "listSSHKeyPairs" }
      
      result = connection.list_object(params, "sshkeypair")
      list_object(columns, result)
    end

  end
end
