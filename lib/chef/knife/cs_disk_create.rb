#
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Copyright:: Copyright (c) 2012 Schuberg Philis.
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
  class CsDiskCreate < Chef::Knife

    deps do
      require 'chef/knife/bootstrap'
      Chef::Knife::Bootstrap.load_deps
      require 'socket'
      require 'net/ssh/multi'
      require 'chef/json_compat'
      require 'knife-cloudstack/connection'
    end

    banner "knife cs disk create [DISK_NAME] (options)"

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
           :description => "The display text of the disk offering"

    option :disksize,
           :short => "-S SIZE",
           :long => "--disksize SIZE",
           :description => "Size of the disk offering in GB"

    option :domain,
           :long => "--domain PATH",
           :description => "The domain path of the domain"

    option :tags,
           :long => "--tags TAGS",
           :description => "The tags for this disk offering"

    option :iscustom,
           :long => "--iscustom",
           :description => "Whether disk offering is custom or not",
           :boolean => true

    def run

      diskname = @name_args.first
      unless /^[a-zA-Z0-9][_a-zA-Z0-9-]*$/.match diskname then
        ui.error "Invalid diskname, please specify a short diskname.\n"
        exit 1
      end
      validate_options

      $stdout.sync = true

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      print "#{ui.color("Creating disk offering: #{diskname}", :magenta)}\n"
      diskoffer = connection.create_diskoffering(
          diskname,
          locate_config_value(:displaytext),
          locate_config_value(:disksize),
          locate_config_value(:domain),
          locate_config_value(:tags),
          locate_config_value(:iscustom)
      )

    end

    def validate_options
      unless locate_config_value :displaytext
        ui.error "The displaytext parameter '-T \"TEXT\"' is missing."
        exit 1
      end

      unless locate_config_value :iscustom
        unless locate_config_value :disksize
          ui.error "The disksize parameter '-S <N>' is missing."
          exit 1
        end
      end
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end # class
end
