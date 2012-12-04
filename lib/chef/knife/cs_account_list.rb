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
  class CsAccountList < Chef::Knife

    deps do
      require 'knife-cloudstack/connection'
    end

    banner "knife cs account list (options)"

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
           :description => "List all the accounts",
           :boolean => true

    option :name,
           :long => "--name NAME",
           :description => "Specify account name to list"

    option :keyword,
           :long => "--keyword KEY",
           :description => "List by keyword"

    option :domainid,
           :long => "--domainid",
           :description => "Show domain ID in the output",
           :boolean => true


    def run

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      account_list = [
          ui.color('Name', :bold),
          ui.color('Domain', :bold),
          ui.color('State', :bold),
          ui.color('Type', :bold),
          ui.color('Users', :bold)
      ]

      account_list = [
          ui.color('Name', :bold),
          ui.color('Domain', :bold),
          ui.color('DomainID', :bold),
          ui.color('State', :bold),
          ui.color('Type', :bold),
          ui.color('Users', :bold)
      ] if locate_config_value(:domainid)


      accounts = connection.list_accounts(
        locate_config_value(:listall),
        locate_config_value(:name),
        locate_config_value(:keyword)
      )

      accounts.each do |s|
        account_list << s['name'].to_s
        account_list << s['domain'].to_s
        account_list << s['domainid'].to_s if locate_config_value(:domainid)
        account_list << s['state'].to_s
        case s['accounttype']
          when 0 then account_list << "user"
          when 1 then account_list << "admin"
          when 2 then account_list << "domain admin"
          else account_list << "unknown"
        end
        account_list << s['user'].count.to_s
      end

      if locate_config_value(:domainid)
        puts ui.list(account_list, :columns_across, 6)
      else
        puts ui.list(account_list, :columns_across, 5)
      end
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
