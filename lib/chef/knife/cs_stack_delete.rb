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

require 'chef/knife'

module KnifeCloudstack
  class CsStackDelete < Chef::Knife

    deps do
      require 'chef/json_compat'
      require 'chef/mash'
      require 'knife-cloudstack/connection'
      KnifeCloudstack::CsServerDelete.load_deps
    end

    banner "knife cs stack delete JSON_FILE (options)"

    option :cloudstack_url,
           :short => "-U URL",
           :long => "--cloudstack-url URL",
           :description => "The CloudStack endpoint URL",
           :proc => Proc.new { |url| Chef::Config[:knife][:cloudstack_url] = url }

    option :cloudstack_api_key,
           :short => "-A KEY",
           :long => "--cloudstack-api-key KEY",
           :description => "Your CloudStack API key",
           :proc => Proc.new { |key| Chef::Config[:knife][:cloudstack_api_key] = key }

    option :cloudstack_secret_key,
           :short => "-K SECRET",
           :long => "--cloudstack-secret-key SECRET",
           :description => "Your CloudStack secret key",
           :proc => Proc.new { |key| Chef::Config[:knife][:cloudstack_secret_key] = key }

    def run
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
