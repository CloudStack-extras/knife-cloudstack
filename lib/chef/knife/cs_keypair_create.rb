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
  class CsKeypairCreate < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      Chef::Knife.load_deps
    end

    banner "knife cs keypair create KEY_NAME (options)"

    option :name,
           :long => "--name NAME",
           :description => "Specify the ssh keypair name"

    option :noheader,
           :long => "--noheader",
           :description => "Removes header from output",
           :boolean => true

    def run
      validate_base_options

      Chef::Log.debug("Validate keypair name")
      keypairname = locate_config_value(:name) || @name_args.first
      unless /^[a-zA-Z0-9][a-zA-Z0-9\-\_]*$/.match(keypairname) then
          ui.error "Invalid keypairname. Please specify a short name for the keypair"
          exit 1
      end

      ui.info("#{ui.color("Creating SSH Keypair: #{keypairname}", :magenta)}") unless locate_config_value(:noheader)

      params = {
        'command' => 'createSSHKeyPair',
        'name' => keypairname,
      }

      json = connection.send_request(params)

      unless json then
        ui.error("Unable to create SSH Keypair")
        exit 1
      end

      fingerprint = json['keypair']['fingerprint'] 
      privatekey  = json['keypair']['privatekey']
      ui.info("Fingerprint: #{fingerprint}") unless locate_config_value(:noheader)
      ui.info(privatekey)
      puts "\n" unless locate_config_value(:noheader)
    end

  end # class
end
