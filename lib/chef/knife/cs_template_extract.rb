#
# Author:: Frank Breedijk (<fbreedijk@schubergphilis.com>)
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
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

require 'chef/knife'
require 'chef/knife/cs_base'

module KnifeCloudstack
  class CsTemplateExtract < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs template extract NAME (options)"

    option :name,
           :long => "--name NAME",
           :description => "Name of template to extract (without format checking)"

    option :zone,
           :long => "--zone NAME",
	   :description => "Name of the zone to extract the template in"

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

      print "#{ui.color("Extracting template: #{templatename}", :magenta)}\n"

      Chef::Log.debug("Getting zone")

      zone = connection.get_zone(
        zonename,
      )
      if ! zone then
        ui.error "Zone #{zonename} not found"
	exit 1
      end

      Chef::Log.debug("Getting template")

      template = connection.get_template(
        templatename,
      )
      if ! template then
        ui.error "Template #{templatename} not found"
	exit 1
      end

      Chef::Log.debug("Extracting template")
      params = {
        'command' => 'extractTemplate',
	'id' => template["id"],
	'mode' => "HTTP_DOWNLOAD",
	'zoneid' => zone["id"]
      }
      json = connection.send_async_request(params)

      if json then
      	url = json["template"]["url"]
        print "\n#{url}\n"
      else
	ui.error "Template extraction failed.\n"
	exit 1
      end
    end

  end # class
end
