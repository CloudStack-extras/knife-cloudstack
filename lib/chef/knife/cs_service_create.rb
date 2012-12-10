#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
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
require 'json'

module KnifeCloudstack
  class CsServiceCreate < Chef::Knife

    deps do
      require 'chef/knife/bootstrap'
      Chef::Knife::Bootstrap.load_deps
      require 'socket'
      require 'net/ssh/multi'
      require 'chef/json_compat'
      require 'knife-cloudstack/connection'
    end

    banner "knife cs service create [SERVICE_NAME] (options)"

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

    option :cpunumber,
           :short => "-C N",
           :long => "--cpunumber N",
           :description => "The CPU number of the service offering"

    option :cpuspeed,
           :short => "-S N",
           :long => "--cpuspeed N",
           :description => "The CPU speed of the service offering in MHz"

    option :memory,
           :short => "-M N",
           :long => "--memory N",
           :description => "The total memory of the service offering in MB"

    option :displaytext,
           :short => "-T 'DISPLAY TEXT' ",
           :long => "--displaytext 'DISPLAY TEXT'",
           :description => "The display text of the service offering"

    option :domain,
           :long => "--domain NAME",
           :description => "The name of the domain"

    option :hosttags,
           :long => "--hosttags TAGS",
           :description => "The host tag for this service offering"

    option :issystem,
           :long => "--issystem",
           :description => "Is this a system vm offering",
           :boolean => true

    option :limitcpuuse,
           :long => "--limitcpuuse",
           :description => "Restrict the CPU usage to committed service offering",
           :boolean => true

    option :networkrate,
           :long => "--networkrate RATE",
           :description => "Rate in megabits per second allowed. Supported only for non-System offering and system offerings having \"domainrouter\" systemvmtype"

    option :offerha,
           :long => "--offerha",
           :description => "Enable HA for the service offering",
           :boolean => true

    option :storagetype,
           :long => "--storagetype TYPE",
           :description => "Storage type of service offering: local or shared"

    option :systemvmtype,
           :long => "--systemvmtype TYPE",
           :description => "System VM type: domainrouter, consoleproxy or secondarystoragevm"

    option :storagetags,
           :long => "--storagetags TAG",
           :description => "The storage tags for this service offering"

    def run

      servicename = @name_args.first
      unless /^[a-zA-Z0-9][_a-zA-Z0-9-]*$/.match servicename then
        ui.error "Invalid servicename, please specify a short servicename.\n"
        exit 1
      end
      validate_options

      $stdout.sync = true

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      print "#{ui.color("Creating service: #{servicename}", :magenta)}\n"
      service = connection.create_service(
          servicename,
          locate_config_value(:cpunumber),
          locate_config_value(:cpuspeed),
          locate_config_value(:displaytext),
          locate_config_value(:memory),
          locate_config_value(:domain),
          locate_config_value(:hosttags),
          locate_config_value(:issystem),
          locate_config_value(:limitcpuuse),
          locate_config_value(:networkrate),
          locate_config_value(:offerha),
          locate_config_value(:storagetype),
          locate_config_value(:systemvmtype),
          locate_config_value(:storagetags)
      )

    end

    def validate_options
      unless locate_config_value :cpunumber 
        ui.error "The cpunumber parameter '-C <N>' is missing."
        exit 1
      end

      unless locate_config_value :cpuspeed
        ui.error "The cpuspeed parameter '-S <N>' is missing."
        exit 1
      end

      unless locate_config_value :displaytext
        ui.error "The displaytext parameter '-T \"TEXT\"' is missing."
        exit 1
      end

      unless locate_config_value :memory
        ui.error "The memory parameter '-M <N>' is missing."
        exit 1
      end
    end


    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end # class
end
