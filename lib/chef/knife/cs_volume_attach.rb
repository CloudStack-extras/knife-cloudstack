#
# Author:: David Bruce <dbruce@schubergphilis.com>
# Copyright:: Copyright (c) Schuberg Philis 2013
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
  class CsVolumeAttach < Chef::Knife
    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      Chef::Knife.load_deps
    end

    banner 'knife cs volume attach NAME VM (options)'

    option :volume,
           :long => '--volume VOLUME_NAME',
           :description => 'Specify volume name to attach'

    option :vm,
           :long => '--vm VM_NAME',
           :description => 'Name of the VM to attach disk to'

    def run
      validate_base_options

      volumename = locate_config_value(:volume) || @name_args[0]
      exit_with_error 'Invalid volume name.' unless valid_cs_name? volumename

      vmname = locate_config_value(:vm) || @name_args[1]
      exit_with_error 'Invalid virtual machine.' unless valid_cs_name? vmname

      volume = connection.get_volume(volumename)
      exit_with_error "Volume #{volumename} not found." unless volume && volume['id']
      exit_with_error "Volume #{volumename} is currently attached." if volume['vmname']

      vm = connection.get_server(vmname)
      exit_with_error "Virtual machine #{vmname} not found." unless vm && vm['id']

      puts ui.color("Attaching volume #{volumename} to #{vmname}", :magenta)

      params = {
        'command' => 'attachVolume',
        'id' => volume['id'],
        'virtualmachineid' => vm['id']
      }

      json = connection.send_request(params)
      exit_with_error 'Unable to attach volume' unless json

      puts "Volume #{volumename} is being attached in the background"

      json['jobid']
    end
  end # class
end
