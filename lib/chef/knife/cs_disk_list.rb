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
           :short => "-s URL",
           :long => "--server-url URL",
           :description => "Your CloudStack endpoint URL",
           :proc => Proc.new { |url| Chef::Config[:knife][:cloudstack_url] = url }

    option :cloudstack_api_key,
           :short => "-k KEY",
           :long => "--key KEY",
           :description => "Your CloudStack API key",
           :proc => Proc.new { |key| Chef::Config[:knife][:cloudstack_api_key] = key }

    option :cloudstack_secret_key,
           :short => "-K SECRET",
           :long => "--secret SECRET",
           :description => "Your CloudStack secret key",
           :proc => Proc.new { |key| Chef::Config[:knife][:cloudstack_secret_key] = key }

    option :use_http_ssl,
           :long => '--[no-]use-http-ssl',
           :description => 'Support HTTPS',
           :boolean => true,
           :default => true

    option :name,
           :long => "--name NAME",
           :description => "Specify servicename to list"

    option :keyword,
           :long => "--service NAME",
           :description => "Specify part of servicename to list"

    option :filter,
           :long => "--filter 'FIELD:NAME'",
           :description => "Specify field and part of name to list"

    option :fields,
           :long => "--fields 'NAME, NAME'",
           :description => "The fields to output, comma-separated"

    option :fieldlist,
           :long => "--fieldlist",
           :description => "The available fields to output, comma-separated",
           :boolean => true

    option :noheader,
           :long => "--noheader",
           :description => "Removes header from output",
           :boolean => true

    def run

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key),
          locate_config_value(:cloudstack_project),
          locate_config_value(:use_http_ssl)
      )

      if locate_config_value(:fields)
        object_list = []
        locate_config_value(:fields).split(',').each { |n| object_list << ui.color(("#{n}").strip, :bold) }
      else
        object_list = [
          ui.color('Name', :bold),
          ui.color('Domain', :bold),
          ui.color('Size', :bold),
          ui.color('Comment', :bold),
          ui.color('Created', :bold)
        ]
      end

      columns = object_list.count
      object_list = [] if locate_config_value(:noheader)

      connection_result = connection.list_object(
        "listDiskOfferings",
        "diskoffering",
        locate_config_value(:filter),
        false,
        locate_config_value(:keyword),
        locate_config_value(:name)
      )

      connection_result.each do |result|
        if locate_config_value(:fields)
          locate_config_value(:fields).downcase.split(',').each { |n| object_list << ((result[("#{n}").strip]).to_s || 'N/A') }
        else
          object_list << result['name'].to_s
          object_list << result['domain'].to_s
          object_list << result['disksize'].to_s + 'GB'
          object_list << result['displaytext'].to_s
          object_list << result['created']
        end
      end
      puts ui.list(object_list, :uneven_columns_across, columns)
      connection.show_object_fields(connection_result) if locate_config_value(:fieldlist)
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
