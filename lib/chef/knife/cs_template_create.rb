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
require 'json'

module KnifeCloudstack
  class CsTemplateCreate < Chef::Knife

    deps do
      require 'socket'
      require 'net/ssh/multi'
      require 'chef/json_compat'
      require 'knife-cloudstack/connection'
    end

    banner "knife cs template create NAME (options)"

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

    option :displaytext,
           :short => "-T 'DISPLAY TEXT' ",
           :long => "--displaytext 'DISPLAY TEXT'",
           :description => "The display text of the template",
           :required => true,
           :on => :head

    option :name,
           :long => "--name NAME",
           :description => "Specify templatename (without format checking)"

    option :ostypeid,
           :long => "--ostypeid ID",
           :description => "Specify OS type ID",
           :required => true,
           :on => :head

    option :volumeid,
           :long => "--volumeid=ID",
           :description => "Specify volume ID",
           :required => true,
           :on => :head

    option :ispublic,
           :long => "--[no-]public",
	   :description => "Make the template public after creation",
	   :boolean => true,
	   :default => false

    option :isfeatured,
           :long => "--[no-]featured",
	   :description => "Make the template featured after creation",
	   :boolean => true,
	   :default => false

    option :passwordenabled,
           :long => "--[no-]passwordenabled",
	   :description => "Make the template password reset enabled  after creation",
	   :boolean => true,
	   :default => true

    option :extractable,
           :logn => "--[no-]extractable",
	   :description => "Make the template extractable after creation",
	   :boolean => "true",
	   :default => false

    def run

      $stdout.sync = true

      Chef::Log.debug("Validate hostname and options")
      if  locate_config_value(:name)
        templatename = locate_config_value(:name)
      else
        templatename = @name_args.first
        unless /^[a-zA-Z0-9][a-zA-Z0-9_\-#]*$/.match templatename then
          ui.error "Invalid templatename. Please specify a simple name without any spaces"
          exit 1
        end
      end

      connection = CloudstackClient::Connection.new(
        locate_config_value(:cloudstack_url),
        locate_config_value(:cloudstack_api_key),
        locate_config_value(:cloudstack_secret_key)
      )

      print "#{ui.color("Creating template: #{templatename}", :magenta)}\n"

      template = connection.create_template(
        templatename,
        locate_config_value(:displaytext),
        locate_config_value(:ostypeid),
        locate_config_value(:volumeid),
	locate_config_value(:ispublic),
	locate_config_value(:isfeatured),
	locate_config_value(:passwordenabled),
	locate_config_value(:extractable)
      )
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end # class
end
