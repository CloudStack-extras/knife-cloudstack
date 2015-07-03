#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2013 Sander Botman.
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

class Chef
  class Knife
    module KnifeCloudstackBase

      def self.included(includer)
        includer.class_eval do

          deps do
            require 'knife-cloudstack/connection'
          end

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

          option :cloudstack_project,
                 :short => "-P PROJECT_NAME",
                 :long => '--cloudstack-project PROJECT_NAME',
                 :description => "Cloudstack Project in which to create server",
                 :proc => Proc.new { |v| Chef::Config[:knife][:cloudstack_project] = v },
                 :default => nil

          option :cloudstack_no_ssl_verify,
                 :long => '--cloudstack-no-ssl-verify',
                 :description => "Disable certificate verify on SSL",
                 :boolean => true

          option :cloudstack_proxy,
                 :long => '--cloudstack-proxy PROXY',
                 :description => "Enable proxy configuration for cloudstack api access"

          def validate_base_options
            unless locate_config_value :cloudstack_url
              ui.error "Cloudstack URL not specified"
              exit 1
            end
            unless locate_config_value :cloudstack_api_key
              ui.error "Cloudstack API key not specified"
              exit 1
            end
            unless locate_config_value :cloudstack_secret_key
              ui.error "Cloudstack Secret key not specified"
              exit 1
            end
          end

          def connection
            @connection ||= CloudstackClient::Connection.new(
              locate_config_value(:cloudstack_url),
              locate_config_value(:cloudstack_api_key),
              locate_config_value(:cloudstack_secret_key),
              locate_config_value(:cloudstack_project),
              locate_config_value(:cloudstack_no_ssl_verify),
              locate_config_value(:cloudstack_proxy)
            )
          end

          def locate_config_value(key)
            key = key.to_sym
            config[key] || Chef::Config[:knife][key] || nil
          end 

          def exit_with_error(error)
            ui.error error
            exit 1
          end

          def valid_cs_name?(name)
            !!(name && /^[a-zA-Z0-9][a-zA-Z0-9_\-#]*$/.match(name))
          end

        end
      end
    end
  end
end
