#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
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

class Chef
  class Knife
    module KnifeCloudstackBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'readline'
            require 'chef/json_compat'
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

          option :use_http_ssl,
                 :long => '--[no-]use-http-ssl',
                 :description => 'Support HTTPS',
                 :boolean => true,
                 :default => true
        end
      end

    end
  end
end
