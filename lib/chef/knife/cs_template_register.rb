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
           :description => "Name of template to register (without format checking)"
    
    option :displaytext,
           :long => "--displaytext DESCRIPTION",
	   :description => "Description of the template as shown in CloudStack"

    option :format,
           :long => "--format FORMAT",
	   :description => "Format of the template file QCOW2, RAW or VHD (default)",
	   :default => "VHD"

    option :hypervisor,
           :long => "--hypervisor NAME",
	   :description => "Target hypervisor for the template (default XEN)",
	   :default => "XenServer"

    option :ostypeid,
	   :long => '--ostypeid OSTYPEID',
           :description => "The ID of the OS Type that best represents the OS of this template"

    option :url,
           :long => '--url URL',
           :description => "The URL of where the template is hosted. Including http:// and https://"

    option :zone,
           :long => "--zone NAME",
	   :description => "Name of the zone to register the template in. Default: All zones",
	   :default => -1

    option :bits,
           :long => "--bits 32|64",
	   :description => "32 or 64 bits support, defaults to 64",
	   :default => 64

    option :extractable,
           :long => "--[no-]extractable",
	   :description => "Is the template extracable. Default: NO",
	   :boolean => true,
	   :default => false

    option :featured,
           :long => "--[no-]featured",
	   :description => "Is the tempalte featured? Default: NO",
	   :boolean => true,
	   :default => false

    option :public,
           :long => "--[no-]public",
	   :description => "Is the template public? Default: NO",
	   :boolean => true,
	   :default => false

    option :passwordenabled,
           :long => "--[no-]passwordenabled",
	   :description => "Is the password reset feature enabled, Default: YES",
	   :boolean => true,
	   :default => true

    option :requireshvm,
           :long => "--[no-]requireshvm",
	   :description => "Does the template require HVM? Default: NO",
	   :boolean => true,
	   :default => false

    option :sshkeyenabled,
           :long => "--[no-]sshkeyenabled",
	   :description => "Does this tempalte support the sshkey upload feature? Default: NO",
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

      unless locate_config_value(:ostypeid) then
        ui.error "No os type id specified"
	exit 1
      end
      
      unless /^http(s)?\:\/\//.match locate_config_value(:url) then
        ui.error "URL (#{locate_config_value(:url)}) is not a well formatted url"
	exit 1
      end

      unless (locate_config_value(:bits) == 64 or locate_config_value(:bits) == 32 ) then
        ui.error "Bits must be 32 or 64"
	exit 1
      end

      connection = CloudstackClient::Connection.new(
        locate_config_value(:cloudstack_url),
        locate_config_value(:cloudstack_api_key),
        locate_config_value(:cloudstack_secret_key),
	locate_config_value(:cloudstack_project),
	locate_config_value(:use_http_ssl)
      )

      if (locate_config_value(:zone) == -1)
        zoneid = -1
      else
      	Chef::Log.debug("Resolving zone #{locate_config_value(:zone)}\n")

	zone = connection.get_zone(locate_config_value(:zone))

	if ! zone then
	  ui.error "Unable to resolve zone #{locate_config_value(:zone)}\n"
	  exit 1
	end
	zoneid = zone['id']
      end

      print "#{ui.color("Registring template: #{templatename}", :magenta)}\n"

      params = {
        'command' => 'registerTemplate',
	'name' => templatename,
        'displaytext' => locate_config_value(:displaytext),
        'format' => locate_config_value(:format),
        'hypervisor' => locate_config_value(:hypervisor),
        'ostypeid' => locate_config_value(:ostypeid),
        'url' => locate_config_value(:url),
        'zoneid' => zoneid,
        'bits' => locate_config_value(:bits),
      }
      params['extracable'] = locate_config_value(:extractable) if locate_config_value(:extractable)
      params['ispublic'] = locate_config_value(:public) if locate_config_value(:public)
      params['isfeatured'] = locate_config_value(:featured) if locate_config_value(:featured)
      params['passwordenabled'] = locate_config_value(:passwordenabled) if locate_config_value(:passwordenabled)
      params['sshkeyenabled'] = locate_config_value(:sshkeyenabled) if locate_config_value(:sshkeyenabled)
      params['requireshvm'] = locate_config_value(:requireshvm) if locate_config_value(:requireshvm)

      json = connection.send_request(params)

      if ! json then
        ui.error "Template #{templatename} not registered\n"
	exit 1
      end

      print "TemplateId #{json['template'][0]['id']} is being created\n"
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end # class
end
