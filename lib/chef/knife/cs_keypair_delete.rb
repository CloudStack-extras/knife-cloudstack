# Copyright:: Copyright (c) 2013 
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

module KnifeCloudstack
  class CsKeypairDelete < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      Chef::Knife.load_deps
    end

    banner "knife cs keypair delete (options)"

    option :name,
           :long => "--name NAME",
           :description => "Specify the ssh keypair name",
           :required => true

    def run
      validate_base_options

      Chef::Log.debug("Validate keypair name")
      if  locate_config_value(:name)
        keypairname = locate_config_value(:name)
      else
          ui.error "Invalid keypairname. Please specify a name for the keypair"
          exit 1
      end

      print "#{ui.color("Deleting the SSH Keypair: #{keypairname}", :magenta)}\n"

      params = {
        'command' => 'deleteSSHKeyPair',
        'name' => keypairname,
      }

      json = connection.send_request(params)

      if ! json then
        ui.error("Unable to delete SSH Keypair")
	exit 1
      end

      object_fields = []
      object_fields << ui.color("Info:", :cyan)
      object_fields << json['displaytext'].to_s
      object_fields << ui.color("Success:", :cyan)
      object_fields << json['success'].to_s

      puts "\n"
      puts ui.list(object_fields, :uneven_columns_across, 2)
      puts "\n"
      
      return
    end

  end # class
end
