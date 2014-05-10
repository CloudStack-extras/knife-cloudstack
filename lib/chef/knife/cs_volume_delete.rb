#
# Author:: Muga Nishizawa (<muga.nishizawa@gmail.com>)
# Copyright:: Copyright (c) 2014 Muga Nishizawa.
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
  class CsVolumeDelete < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      require 'chef/api_client'
      require 'chef/knife'
      Chef::Knife.load_deps
    end

    banner "knife cs volume delete VOLUME_NAME [VOLUME_NAME ...] (options)"

    def run
      validate_base_options

      @name_args.each do |volume_name|
        volume = connection.get_volume(volume_name)

        if !volume then
          ui.error("Volume '#{volume_name}' not found")
          next
        end

        if vmn = volume['vmname']
          ui.error("Volume '#{volume_name}' attached to VM '#{vmn}'")
          ui.error("You should detach it from VM to delete the volume.")
          next
        end

        show_object_details(volume)

        result = confirm_action("Do you really want to delete this volume")
        if result
          print "#{ui.color("Waiting for deletion", :magenta)}"
          connection.delete_volume(volume_name)
          puts "\n"
          ui.msg("Deleted volume #{volume_name}")
        end
      end
    end

    def show_object_details(v)
      return if locate_config_value(:yes)

      object_fields = []
      object_fields << ui.color("Name:", :cyan)
      object_fields << v['name'].to_s
      object_fields << ui.color("Account:", :cyan)
      object_fields << v['account']
      object_fields << ui.color("Domain:", :cyan)
      object_fields << v['domain']
      object_fields << ui.color("State:", :cyan)
      object_fields << v['state']
      object_fields << ui.color("VMName:", :cyan)
      object_fields << v['vmname']
      object_fields << ui.color("VMState:", :cyan)
      object_fields << v['vmstate']

      puts "\n"
      puts ui.list(object_fields, :uneven_columns_across, 2)
      puts "\n"
    end

    def confirm_action(question)
      return true if locate_config_value(:yes)
      result = ui.ask_question(question, :default => "Y" )
      if result == "Y" || result == "y" then
        return true
      else
        return false
      end
    end

  end
end
