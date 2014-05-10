#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2014
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
    module CsBase

      # :nodoc:
      # Would prefer to do this in a rational way, but can't be done b/c of
      # Mixlib::CLI's design :(
      def self.included(includer)
        includer.class_eval do

          deps do
            require 'fog'
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
        end
      end


      def connection
        @connection ||= begin
          cloudstack_uri =  URI.parse(Chef::Config[:knife][:cloudstack_url])
          connection = Fog::Compute.new(
              :provider              => :cloudstack,
              :cloudstack_api_key    => Chef::Config[:knife][:cloudstack_api_key],
              :cloudstack_secret_access_key => Chef::Config[:knife][:cloudstack_secret_key],
              :cloudstack_host       => cloudstack_uri.host,
              :cloudstack_port       => cloudstack_uri.port,
              :cloudstack_path       => cloudstack_uri.path,
              :cloudstack_scheme     => cloudstack_uri.scheme
          )
        end
      end

      def locate_config_value(key)
        key = key.to_sym
        config[key] || Chef::Config[:knife][key]
      end

      def msg_pair(label, value, color=:cyan)
        if value && !value.to_s.empty?
          puts "#{ui.color(label, color)}: #{value}"
        end
      end

      def is_image_windows?
        image_info = connection.images.get(@server.image_id)
        return image_info.platform == 'windows'
      end

      def validate!
        errors = []
        # simple validation for the moment, we need to impove this later.

        if locate_config_value(:cloudstack_url).nil?
          errors << "Please provide the API url within the configuration or with the option -U"
        end

        if locate_config_value(:cloudstack_api_key).nil?
          errors << "Please provide the API key within the configuration or with the option -A"
        end

        if locate_config_value(:cloudstack_secret_key).nil?
          errors << "Please provide the secret key within the configuration or with the option -K"
        end

        if errors.each{|e| ui.error(e)}.any?
          exit 1
        end
      end

    end

    def iam_name_from_profile(profile)
      # The IAM profile object only contains the name as part of the arn
      if profile && profile.key?('arn')
        name = profile['arn'].split('/')[-1]
      end
      name ||= ''
    end
  end
end