#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Author:: Frank Breedijk (<fbreedijk@schubergphilis.com>)
# Copyright:: Copyright (c) 2012 Schuberg Philis.
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
#require 'json'

module KnifeCloudstack
  class CsTemplateRegister < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs template register NAME (options)"

    option :name,
           :long => "--name NAME",
           :description => "Name of template to extract (without format checking)"
    
    option :description,
           :long => "--description DESCRIPTION",
	   :description => "Description of the template as shown in CloudStack"

    option :format,
           :long => "--format FORMAT",
	   :description => "Format of the template file QCOW2, RAW or VHD (default)",
	   :default => "VHD"

    option :hypervisor,
           :long => "--hypervisor NAME",
	   :description => "Target hypervisor for the template (default XEN)",
	   :default => "XenServer"

    option :ostype,
           :description => "The ID of the OS Type that best represents the OS of this template"

    option :url,
           :description => "The URL of where the template is hosted. Including http:// and https://"

    option :zone,
           :long => "--zone NAME",
	   :description => "Name of the zone to extract the template in. Default: All zones",
	   :default => -1

    option :bits,
           :long => "--bits 32|64",
	   :description => "32 or 64 bits support, defaults to 64",
	   :default => 64

    option :extracable,
           :long => "--[no-]extractable",
	   :description => "Is the template extracable. Default: NO",
	   :boolean => true,
	   :default => false

    option :featured,
           :long => "--[no-]featured",
	   :description => "Is the tempalte featured? Default: NO",
	   :boolean => true,
	   :default => false

    def run

      $stdout.sync = true

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

      connection = CloudstackClient::Connection.new(
        locate_config_value(:cloudstack_url),
        locate_config_value(:cloudstack_api_key),
        locate_config_value(:cloudstack_secret_key),
	locate_config_value(:cloudstack_project),
	locate_config_value(:use_http_ssl)
      )

      print "#{ui.color("Extracting template: #{templatename}", :magenta)}\n"

      Chef::Log.debug("Getting template")

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
      extract = connection.extract_template(
        template["id"],
	"HTTP_DOWNLOAD",
	nil,
	zone["id"]
      )

      if extract then
      	url = extract["template"]["url"]
        print "\n#{url}\n"
      else
	ui.error "Template extraction failed.\n"
	exit 1
      end
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end # class
end
