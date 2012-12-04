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

module KnifeCloudstack
  class CsDiskList < Chef::Knife

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs disk list (options)"

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

    def run

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      diskoffer_list = [
          ui.color('Name', :bold),
          ui.color('Domain', :bold),
          ui.color('Size', :bold),
          ui.color('Comment', :bold),
          ui.color('Created', :bold)
      ]

      diskoffer = connection.list_disk_offerings

      diskoffer.each do |s|
        diskoffer_list << s['name'].to_s
        diskoffer_list << s['domain'].to_s
        diskoffer_list << s['disksize'].to_s + ' GB'
        diskoffer_list << s['displaytext'].to_s
        diskoffer_list << s['created']
      end
      puts ui.list(diskoffer_list, :columns_across, 5)

    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
