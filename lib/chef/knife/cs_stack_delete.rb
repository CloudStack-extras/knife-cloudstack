#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Copyright:: Copyright (c) 2011 Edmunds, Inc.
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
  class CsStackDelete < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'chef/json_compat'
      require 'chef/mash'
      require 'knife-cloudstack/connection'
      require 'chef/knife'
      Chef::Knife.load_deps
      KnifeCloudstack::CsServerDelete.load_deps
    end

    banner "knife cs stack delete JSON_FILE (options)"

    def run
      if @name_args.first.nil?
        ui.error "Please specify json file eg: knife cs stack delete JSON_FILE"
        exit 1
      end
      file_path = File.expand_path(@name_args.first)
      unless File.exist?(file_path) then
        ui.error "Stack file '#{file_path}' not found. Please check the path."
        exit 1
      end

      data = File.read file_path
      stack = Chef::JSONCompat.from_json data
      delete_stack stack

    end

    def delete_stack(stack)
      current_stack = Mash.new(stack)
      current_stack[:servers].each do |server|
        if server[:name]

          # delete server(s)
          names = server[:name].split(/[\s,]+/)
          names.each do |name|
            delete_server(name)
          end

        end

      end
    end

    def delete_server(server_name)
      cmd = KnifeCloudstack::CsServerDelete.new([server_name])
      cmd.config[:yes] = true
      cmd.run_with_pretty_exceptions
    end

  end

end
