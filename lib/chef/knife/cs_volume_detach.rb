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
  class CsVolumeDetach < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      Chef::Knife.load_deps
    end

    banner 'knife cs volume detach NAME (options)'

    option :name,
           :long => '--name',
           :description => 'Specify volume name to detach'

    def run
      validate_base_options

      volumename = locate_config_value(:volume) || @name_args[0]
      exit_with_error 'Invalid volumename.' unless valid_cs_name? volumename

      volume = connection.get_volume(volumename)
      exit_with_error "Volume #{volumename} not found." unless volume && volume['id']
      exit_with_error "Volume #{volumename} is not attached." unless volume['vmname']

      puts ui.color("Detaching volume: #{volumename}", :magenta)

      params = {
        'command' => 'detachVolume',
        'id' => volume['id']
      }

      json = connection.send_async_request(params)
      exit_with_error 'Unable to detach volume' unless json

      puts "Volume #{volumename} is now detached."

    end
  end # class
end
