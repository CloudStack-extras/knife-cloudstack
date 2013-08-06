#
# Author:: Jeremy Baumont (<jbaumont@schubergphilis.com>)
# Copyright:: Copyright (c) Schuberg Philis 2013 
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

module KnifeCloudstack
    class CsVolumeCreate < Chef::Knife

	include Chef::Knife::KnifeCloudstackBase

	deps do
	    require 'knife-cloudstack/connection'
	    Chef::Knife.load_deps
	end

	banner "knife cs volume create NAME (options)"

	option :name,
	    :long => "--name NAME",
	    :description => "The name of the disk volume.",
	    :required => true,
	    :on => :head

	option :account,
	    :long => "--account ACCOUNT_NAME",
	    :description => "The account associated with the disk volume. Must be used with the domainId parameter."

	option :diskofferingid,
	    :long => "--diskofferingid ID",
	    :description => "The ID of the disk offering. Either diskOfferingId or snapshotId must be passed in."

	option :domainid,
	    :long => "--domainid ID",
	    :description => "The domain ID associated with the disk offering. If used with the account parameter returns the disk volume associated with the account for the specified domain."

	option :size,
	    :long => "--size SIZE",
	    :description => "Arbitrary volume size."

	option :snapshotid,
	    :long => "--snapshotid ID",
	    :description => "The snapshot ID for the disk volume. Either diskOfferingId or snapshotId must be passed in."

	option :zoneid,
	    :long => "--zoneid ID",
	    :description => "The ID of the availability zone.",
	    :required => true,
	    :on => :head


	def run
	    validate_base_options

	    Chef::Log.debug("Validate hostname and options")
	    if  locate_config_value(:name)
		volumename = locate_config_value(:name)
	    else
		volumename = @name_args.first
		unless /^[a-zA-Z0-9][a-zA-Z0-9_\-#]*$/.match volumename then
		    ui.error "Invalid volumename. Please specify a simple name without any spaces"
		    exit 1
		end
	    end

	    print "#{ui.color("Creating volume: #{volumename}", :magenta)}\n"

	    params = {
		'command' => 'createVolume',
		'name' => volumename,
	    }

	    params['account'] = locate_config_value(:account) if locate_config_value(:account)
	    params['diskofferingid'] = locate_config_value(:diskofferingid) if locate_config_value(:diskofferingid)
	    params['domainid'] = locate_config_value(:domainid) if locate_config_value(:domainid)
	    params['projectid'] = locate_config_value(:projectid) if locate_config_value(:projectid)
	    params['size'] = locate_config_value(:size) if locate_config_value(:size)
	    params['snapshotid'] = locate_config_value(:snapshotid) if locate_config_value(:snapshotid)
	    params['zoneid'] = locate_config_value(:zoneid) if locate_config_value(:zoneid)

	    json = connection.send_request(params)

	    if ! json then
		ui.error("Unable to create volume")
		exit 1
	    end

	    print "Volume #{json['id']} is being created in the background\n";

	    return json['id']
	end

    end # class
end
