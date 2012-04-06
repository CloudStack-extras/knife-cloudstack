#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Copyright:: Copyright (c) 2011 Edmunds, Inc.
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
require 'json'

module KnifeCloudstack
  class CsServerCreate < Chef::Knife

    # Seconds to delay between detecting ssh and initiating the bootstrap
    BOOTSTRAP_DELAY = 3

    # Seconds to wait between ssh pings
    SSH_POLL_INTERVAL = 2

    deps do
      require 'chef/knife/bootstrap'
      Chef::Knife::Bootstrap.load_deps
      require 'socket'
      require 'net/ssh/multi'
      require 'chef/json_compat'
      require 'knife-cloudstack/connection'
    end

    banner "knife cs server create [SERVER_NAME] (options)"

    option :cloudstack_service,
           :short => "-S SERVICE",
           :long => "--service SERVICE",
           :description => "The CloudStack service offering name",
           :proc => Proc.new { |o| Chef::Config[:knife][:cloudstack_service] = o },
           :default => "M"

    option :cloudstack_template,
           :short => "-T TEMPLATE",
           :long => "--template TEMPLATE",
           :description => "The CloudStack template for the server",
           :proc => Proc.new { |t| Chef::Config[:knife][:cloudstack_template] = t }

    option :cloudstack_zone,
           :short => "-Z ZONE",
           :long => "--zone ZONE",
           :description => "The CloudStack zone for the server",
           :proc => Proc.new { |z| Chef::Config[:knife][:cloudstack_zone] = z }

    option :cloudstack_networks,
           :short => "-W NETWORKS",
           :long => "--networks NETWORK",
           :description => "Comma separated list of CloudStack network names",
           :proc => lambda { |n| n.split(',').map {|sn| sn.strip}} ,
           :default => []

    option :public_ip,
           :long => "--[no-]public-ip",
           :description => "Allocate a public IP for this server",
           :boolean => true,
           :default => true

    option :chef_node_name,
           :short => "-N NAME",
           :long => "--node-name NAME",
           :description => "The Chef node name for your new node"

    option :ssh_user,
           :short => "-x USERNAME",
           :long => "--ssh-user USERNAME",
           :description => "The ssh username"

    option :ssh_password,
           :short => "-P PASSWORD",
           :long => "--ssh-password PASSWORD",
           :description => "The ssh password"

    option :identity_file,
           :short => "-i IDENTITY_FILE",
           :long => "--identity-file IDENTITY_FILE",
           :description => "The SSH identity file used for authentication"

    option :cloudstack_url,
           :short => "-U URL",
           :long => "--cloudstack-url URL",
           :description => "The CloudStack API endpoint URL",
           :proc => Proc.new { |u| Chef::Config[:knife][:cloudstack_url] = u }

    option :cloudstack_api_key,
           :short => "-A KEY",
           :long => "--cloudstack-api-key KEY",
           :description => "Your CloudStack API key",
           :proc => Proc.new { |k| Chef::Config[:knife][:cloudstack_api_key] = k }

    option :cloudstack_secret_key,
           :short => "-K SECRET",
           :long => "--cloudstack-secret-key SECRET",
           :description => "Your CloudStack secret key",
           :proc => Proc.new { |s| Chef::Config[:knife][:cloudstack_secret_key] = s }

    option :prerelease,
           :long => "--prerelease",
           :description => "Install the pre-release chef gems"

    option :bootstrap_version,
           :long => "--bootstrap-version VERSION",
           :description => "The version of Chef to install",
           :proc => Proc.new { |v| Chef::Config[:knife][:bootstrap_version] = v }

    option :distro,
           :short => "-d DISTRO",
           :long => "--distro DISTRO",
           :description => "Bootstrap a distro using a template",
           :proc => Proc.new { |d| Chef::Config[:knife][:distro] = d },
           :default => "ubuntu10.04-gems"

    option :template_file,
           :long => "--template-file TEMPLATE",
           :description => "Full path to location of template to use",
           :proc => Proc.new { |t| Chef::Config[:knife][:template_file] = t },
           :default => false

    option :run_list,
           :short => "-r RUN_LIST",
           :long => "--run-list RUN_LIST",
           :description => "Comma separated list of roles/recipes to apply",
           :proc => lambda { |o| o.split(/[\s,]+/) },
           :default => []

    option :no_host_key_verify,
           :long => "--no-host-key-verify",
           :description => "Disable host key verification",
           :boolean => true,
           :default => false

    option :no_bootstrap,
           :long => "--no-bootstrap",
           :description => "Disable Chef bootstrap",
           :boolean => true,
           :default => false

    option :port_rules,
           :short => "-p PORT_RULES",
           :long => "--port-rules PORT_RULES",
           :description => "Comma separated list of port forwarding rules, e.g. '25,53:4053,80:8080:TCP'",
           :proc => lambda { |o| o.split(/[\s,]+/) },
           :default => []


    def run

      # validate hostname and options
      hostname = @name_args.first
      unless /^[a-zA-Z0-9][a-zA-Z0-9-]*$/.match hostname then
        ui.error "Invalid hostname. Please specify a short hostname, not an fqdn (e.g. 'myhost' instead of 'myhost.domain.com')."
        exit 1
      end
      validate_options

      $stdout.sync = true

      connection = CloudstackClient::Connection.new(
          locate_config_value(:cloudstack_url),
          locate_config_value(:cloudstack_api_key),
          locate_config_value(:cloudstack_secret_key)
      )

      print "#{ui.color("Waiting for server", :magenta)}"
      server = connection.create_server(
          hostname,
          locate_config_value(:cloudstack_service),
          locate_config_value(:cloudstack_template),
          locate_config_value(:cloudstack_zone),
          locate_config_value(:cloudstack_networks)
      )

      public_ip = find_or_create_public_ip(server, connection)

      puts "\n\n"
      puts "#{ui.color("Name", :cyan)}: #{server['name']}"
      puts "#{ui.color("Public IP", :cyan)}: #{public_ip}"

      return if config[:no_bootstrap]

      print "\n#{ui.color("Waiting for sshd", :magenta)}"

      print(".") until is_ssh_open?(public_ip) {
        sleep BOOTSTRAP_DELAY
        puts "\n"
      }

      bootstrap_for_node(public_ip).run

      puts "\n"
      puts "#{ui.color("Name", :cyan)}: #{server['name']}"
      puts "#{ui.color("Public IP", :cyan)}: #{public_ip}"
      puts "#{ui.color("Environment", :cyan)}: #{config[:environment] || '_default'}"
      puts "#{ui.color("Run List", :cyan)}: #{config[:run_list].join(', ')}"

    end

    def validate_options

      unless locate_config_value :cloudstack_template
        ui.error "Cloudstack template not specified"
        exit 1
      end

      unless locate_config_value :cloudstack_service
        ui.error "Cloudstack service offering not specified"
        exit 1
      end

      identity_file = locate_config_value :identity_file
      ssh_user = locate_config_value :ssh_user
      ssh_password = locate_config_value :ssh_password
      unless identity_file || (ssh_user && ssh_password)
        ui.error("You must specify either an ssh identity file or an ssh user and password")
        exit 1
      end
    end


    def find_or_create_public_ip(server, connection)
      nic = connection.get_server_default_nic(server) || {}
      #puts "#{ui.color("Not allocating public IP for server", :red)}" unless config[:public_ip]
      if (config[:public_ip] == false) || (nic['type'] != 'Virtual') then
        nic['ipaddress']
      else
        # create ip address, ssh forwarding rule and optional forwarding rules
        ip_address = connection.associate_ip_address(server['zoneid'])
        ssh_rule = connection.create_port_forwarding_rule(ip_address['id'], "22", "TCP", "22", server['id'])
        create_port_forwarding_rules(ip_address['id'], server['id'], connection)
        ssh_rule['ipaddress']
      end
    end

    def create_port_forwarding_rules(ip_address_id, server_id, connection)
      rules = locate_config_value(:port_rules)
      return unless rules

      rules.each do |rule|
        args = rule.split(':')
        public_port = args[0]
        private_port = args[1] || args[0]
        protocol = args[2] || "TCP"
        connection.create_port_forwarding_rule(ip_address_id, private_port, protocol, public_port, server_id)
      end

    end

    #noinspection RubyArgCount,RubyResolve
    def is_ssh_open?(ip)
      s = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      sa = Socket.sockaddr_in(22, ip)

      begin
        s.connect_nonblock(sa)
      rescue Errno::EINPROGRESS
        resp = IO.select(nil, [s], nil, 1)
        if resp.nil?
          sleep SSH_POLL_INTERVAL
          return false
        end

        begin
          s.connect_nonblock(sa)
        rescue Errno::EISCONN
          Chef::Log.debug("sshd accepting connections on #{ip}")
          yield
          return true
        rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
          sleep SSH_POLL_INTERVAL
          return false
        end
      ensure
        s && s.close
      end
    end


    def bootstrap_for_node(host)
      bootstrap = Chef::Knife::Bootstrap.new
      bootstrap.name_args = [host]
      bootstrap.config[:run_list] = config[:run_list]
      bootstrap.config[:ssh_user] = config[:ssh_user]
      bootstrap.config[:ssh_password] = config[:ssh_password]
      bootstrap.config[:identity_file] = config[:identity_file]
      bootstrap.config[:chef_node_name] = config[:chef_node_name] if config[:chef_node_name]
      bootstrap.config[:prerelease] = config[:prerelease]
      bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
      bootstrap.config[:distro] = locate_config_value(:distro)
      bootstrap.config[:use_sudo] = true
      bootstrap.config[:template_file] = locate_config_value(:template_file)
      bootstrap.config[:environment] = config[:environment]
      # may be needed for vpc_mode
      bootstrap.config[:no_host_key_verify] = config[:no_host_key_verify]
      bootstrap
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end # class
end
