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
  class CsDomainList < Chef::Knife

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs domain list (options)"

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

    option :listall,
           :long => "--listall",
           :description => "List all the domains",
           :boolean => true
    
    def run

      $stdout.sync = true

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      domain_list = [
          ui.color('Name', :bold),
          ui.color('ID', :bold),
          ui.color('Level', :bold),
          ui.color('Path', :bold)
      ]

      domains = connection.list_domains(locate_config_value(:listall))
      domains.each do |domain|
        domain_list << domain['name'].to_s
        domain_list << domain['id'].to_s
        domain_list << domain['level'].to_s
        domain_list << domain['path'].to_s
      end
      puts ui.list(domain_list, :columns_across, 4)
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
