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

require 'chef/knife/cs_base'

class Chef
  class Knife
    class CsServerList < Knife

      include Chef::Knife::CsBase

      banner "knife cs server list (options)"

      option :id,
             :short => "-i",
             :long => "--id",
             :boolean => true,
             :default => false,
             :description => "Display the ID's instead of the names in output"

      option :tags,
             :short => "-t TAG1,TAG2",
             :long => "--tags TAG1,TAG2",
             :description => "List of tags to output"

      def fcolor(flavor)
        case flavor
          when /.*micro.*/i
            fcolor = :blue
          when /.*small.*/i
            fcolor = :magenta
          when /.*medium.*/i
            fcolor = :cyan
          when /.*large.*/i
            fcolor = :green
          when /.*xlarge.*/i
            fcolor = :red
        end
      end

      def azcolor(az)
        case az
          when /a$/
            color = :blue
          when /b$/
            color = :green
          when /c$/
            color = :red
          when /d$/
            color = :magenta
          else
            color = :cyan
        end
      end

      def groups_with_ids(groups)
        groups.map{|g|
          "#{g} (#{@group_id_hash[g]})"
        }
      end

      def vpc_with_name(vpc_id)
        this_vpc = @vpcs.select{|v| v.id == vpc_id }.first
        if this_vpc.tags["Name"]
          vpc_name = this_vpc.tags["Name"]
          "#{vpc_name} (#{vpc_id})"
        else
          vpc_id
        end
      end

      def private_ip_address(server)
        return nil if server.nics.empty?
        default_nic = server.nics.select {|n| n['isdefault'] == true }.first
        return nil if default_nic.nil? || default_nic.empty?
        default_nic['ipaddress']
      end


      def run
        $stdout.sync = true

        validate!

        server_list = [

            if config[:id]
              ui.color('ID', :bold)
            else
              ui.color('Name', :bold)
            end,

            ui.color('Public IP', :bold),
            ui.color('Private IP', :bold),

            ui.color('Service', :bold),
            ui.color('Image', :bold),
            ui.color('Zone', :bold),
            ui.color('State', :bold)

        ].flatten.compact

        output_column_count = server_list.length

        connection.servers.all.each do |server|

          config[:id] ? server_list << server.id.to_s : server_list << server.name.to_s

          # Still need to fix the public IP's (need to call the API for all forwards and filter on ssh/winrm sessions or something)
          server_list << "pub_ip" # public_ip_address(server).to_s || "unknown"
          server_list << private_ip_address(server).to_s || "unknown"

          config[:id] ? server_list << server.flavor_id.to_s : server_list << server.flavor_name.to_s
          config[:id] ? server_list << server.image_id.to_s : server_list << server.image_name.to_s
          config[:id] ? server_list << server.zone_id.to_s : server_list << server.zone_name.to_s

          server_list << begin
            state = server.state.to_s.downcase
            case state
              when 'destroyed', 'expunging'
                ui.color(state, :purple)
              when 'shutting-down','terminated','stopping','stopped'
                ui.color(state, :red)
              when 'pending'
                ui.color(state, :yellow)
              else
                ui.color(state, :green)
            end
          end
        end

        puts ui.list(server_list, :uneven_columns_across, output_column_count)

      end
    end
  end
end