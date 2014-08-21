#
# Author:: Warren Bain (<warren@ninefold.com>)
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
  class CsTemplateUpdate < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
      Chef::Knife.load_deps
    end

    banner "knife cs template update NAME (options)"

    option :name,
           :long => "--name NAME",
           :description => "Specify templatename (without format checking)"

    option :zone,
           :long => "--zone NAME",
	         :description => "Name of the zone to update the template in"

    option :ispublic,
           :long => "--[no-]public",
           :description => "Make the template public",
           :boolean => true

    option :isfeatured,
           :long => "--[no-]featured",
	         :description => "Make the template featured",
	         :boolean => true

    option :isextractable,
           :long => "--[no-]extractable",
	         :description => "Make the template extractable",
	         :boolean => true

    def run
      validate_base_options

      Chef::Log.debug("Validate template name")
      if  locate_config_value(:name)
        templatename = locate_config_value(:name)
      else
        templatename = @name_args.first
        unless /^[a-zA-Z0-9][a-zA-Z0-9_\-# ]*$/.match templatename then
          ui.error "Invalid templatename."
          exit 1
        end
      end

      zonename = locate_config_value(:zone)
      if ! zonename
      then
        ui.error "No zone specified"
	      exit 1
      end

      Chef::Log.debug("Getting zone")

      zone = connection.get_zone(
        zonename
      )
      if ! zone then
        ui.error "Zone #{zonename} not found"
	      exit 1
      end

      Chef::Log.debug("Getting template")

      template = connection.get_template(
        templatename, zonename
      )
      if ! template then
        ui.error "Template #{templatename} not found"
	      exit 1
      end

      Chef::Log.debug("Updating template")

      params = {
        'command' => 'updateTemplatePermissions',
        'id' => template['id']
      }
      params['ispublic'] = locate_config_value(:ispublic) if locate_config_value(:ispublic)
      params['isfeatured'] = locate_config_value(:isfeatured) if locate_config_value(:isfeatured)
      params['isextractable'] = locate_config_value(:isextractable) if locate_config_value(:isextractable)
      json = connection.send_request(params)

      Chef::Log.debug("Result: #{json}")

      if json['success'] then
        print "Template updated.\n"
      else
        ui.error("Unable to update template: #{json['displaytext']}")
	      exit 1
      end
    end

  end # class
end
