#
# Author:: Ryan Holmes (<rholmes@edmunds.com>)
# Author:: Sander Botman (<sbotman@schubergphilis.com>)
# Author:: Sander van Harmelen (<svanharmelen@schubergphilis.com>)
# Copyright:: Copyright (c) 2011 Edmunds, Inc.
# Copyright:: Copyright (c) 2013 Sander Botman.
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
require 'chef/knife/winrm_base'

module KnifeCloudstack
  class CsServerCreate < Chef::Knife

    include Chef::Knife::KnifeCloudstackBase
    include Chef::Knife::WinrmBase

    # Seconds to delay between detecting ssh and initiating the bootstrap
    BOOTSTRAP_DELAY = 20
    #The machine will reboot once so we need to handle that
    WINRM_BOOTSTRAP_DELAY = 200

    # Seconds to wait between ssh pings
    SSH_POLL_INTERVAL = 10

    deps do
      require 'chef/knife/bootstrap'
      require 'chef/knife/bootstrap_windows_winrm'
      require 'chef/knife/bootstrap_windows_ssh'
      require 'chef/knife/core/windows_bootstrap_context'
      require 'chef/knife/winrm'
      require 'socket'
      require 'net/ssh/multi'
      require 'chef/knife'
      require 'chef/knife/bootstrap'
      require 'chef/json_compat'
      require 'knife-cloudstack/connection'
      require 'winrm'
      require 'httpclient'
      require 'em-winrm'
      Chef::Knife::Bootstrap.load_deps
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

    option :cloudstack_disk,
           :short => "-D DISK",
           :long => "--disk DISK",
           :description => "The CloudStack disk offering name",
           :proc => Proc.new { |d| Chef::Config[:knife][:cloudstack_disk] = d }

    option :cloudstack_hypervisor,
           :long => '--cloudstack-hypervisor HYPERVISOR',
           :description => "The CloudStack hypervisor type for the server"

    option :cloudstack_password,
           :long => "--cloudstack-password",
           :description => "Enables auto-generated passwords by Cloudstack",
           :boolean => true

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

    option :ssh_port,
           :long => "--ssh-port PORT",
           :description => "The ssh port",
           :default => "22"

    option :identity_file,
           :short => "-i IDENTITY_FILE",
           :long => "--identity-file IDENTITY_FILE",
           :description => "The SSH identity file used for authentication"

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
           :default => "chef-full"

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

    option :bootstrap,
           :long => "--[no-]bootstrap",
           :description => "Disable Chef bootstrap",
           :boolean => true,
           :default => true

    option :port_rules,
           :short => "-p PORT_RULES",
           :long => "--port-rules PORT_RULES",
           :description => "Comma separated list of port forwarding rules, e.g. '25,53:4053,80:8080:TCP'",
           :proc => lambda { |o| o.split(/[\s,]+/) },
           :default => []

    option :keypair,
           :long => "--keypair NAME",
           :description => "Name of the keypair that should be used to create the vm",
           :default => false

    option :static_nat,
           :long => '--static-nat',
           :description => 'Support Static NAT',
           :boolean => true,
           :default => false

    option :ipfwd_rules,
           :long => "--ipfwd-rules PORT_RULES",
           :description => "Comma separated list of ip forwarding rules, e.g. '1024:10000:TCP,1024:2048,22'",
           :proc => lambda { |o| o.split(/[\s,]+/) },
           :default => []

    option :fw_rules,
           :short => "-f PORT_RULES",
           :long => "--fw-rules PORT_RULES",
           :description => "Comma separated list of firewall rules, e.g. 'TCP:192.168.0.0/16:1024:65535,TCP::22,UDP::123,ICMP'",
           :proc => lambda { |o| o.split(/[\s,]+/) },
           :default => []

    option :bootstrap_protocol,
           :long => "--bootstrap-protocol protocol",
           :description => "Protocol to bootstrap windows servers. options: winrm/ssh",
           :default => "ssh"

    option :fqdn,
           :long => '--fqdn',
           :description => "FQDN which Kerberos Understands (only for Windows Servers)"

    option :set_display_name,
           :long => '--set-display-name',
           :description => "Set the same server display name as Chef node name.",
           :boolean => true,
           :default => false


    def run
      validate_base_options

      Chef::Log.debug("Validate hostname and options")
      hostname = @name_args.first
      unless /^[a-zA-Z0-9][a-zA-Z0-9-]*$/.match hostname then
        ui.error "Invalid hostname. Please specify a short hostname, not an fqdn (e.g. 'myhost' instead of 'myhost.domain.com')."
        exit 1
      end
      validate_options

      # This little peace of code sets the Chef node-name to the VM name when a node-name is not specifically given
      unless locate_config_value :chef_node_name
        Chef::Config[:knife][:chef_node_name] = @name_args.first
      end

      if @windows_image and locate_config_value(:kerberos_realm)
        Chef::Log.debug("Load additional gems for AD/Kerberos Authentication")
        if @windows_platform
          require 'em-winrs'
        else
          require 'gssapi'
        end
      end

      $stdout.sync = true

      Chef::Log.info("Creating instance with
        service : #{locate_config_value(:cloudstack_service)}
        template : #{locate_config_value(:cloudstack_template)}
        disk : #{locate_config_value(:cloudstack_disk)}
        zone : #{locate_config_value(:cloudstack_zone)}
        project: #{locate_config_value(:cloudstack_project)}
        network: #{locate_config_value(:cloudstack_networks)}")

      print "\n#{ui.color("Waiting for Server to be created", :magenta)}"
      params = {}
      params['hypervisor'] = locate_config_value(:cloudstack_hypervisor) if locate_config_value(:cloudstack_hypervisor)

      params['keypair'] = locate_config_value :keypair  if locate_config_value :keypair
      params['displayname'] = if locate_config_value :set_display_name and locate_config_value :chef_node_name then locate_config_value :chef_node_name else hostname end

      server = connection.create_server(
          hostname,
          locate_config_value(:cloudstack_service),
          locate_config_value(:cloudstack_template),
          locate_config_value(:cloudstack_disk),
          locate_config_value(:cloudstack_zone),
          locate_config_value(:cloudstack_networks),
          params
      )

      zone_name = locate_config_value(:cloudstack_zone)
      zone = zone_name ? connection.get_zone(zone_name) : connection.get_default_zone

      config[:public_ip] = false if zone['networktype'] == 'Basic'
      public_ip = find_or_create_public_ip(server, connection)

      object_fields = []
      object_fields << ui.color("Name:", :cyan)
      object_fields << server['name'].to_s
      object_fields << ui.color("Password:", :cyan) if locate_config_value(:cloudstack_password)
      object_fields << server['password'] if locate_config_value(:cloudstack_password)
      object_fields << ui.color("Public IP:", :cyan)
      object_fields << public_ip

      puts "\n"
      puts ui.list(object_fields, :uneven_columns_across, 2)
      puts "\n"

      return unless config[:bootstrap]

      if @bootstrap_protocol == 'ssh'
        print "\n#{ui.color("Waiting for sshd on: #{public_ip}", :magenta)}"

        print(".") until is_ssh_open?(public_ip) {
          sleep BOOTSTRAP_DELAY
          puts "\n"
        }
      elsif @bootstrap_protocol == 'winrm'
        print "\n#{ui.color("Waiting for winrm to be active on: #{public_ip}", :magenta)}"
        print(".") until tcp_test_winrm(public_ip,locate_config_value(:winrm_port)) {
          sleep WINRM_BOOTSTRAP_DELAY
          puts("\n")
        }
      else
        puts "Cannot determine the bootstrap protocol."
        puts "Please specify either ssh or winrm as bootstrap protocol."
        exit 1
      end

      object_fields = []
      object_fields << ui.color("Name:", :cyan)
      object_fields << server['name'].to_s
      object_fields << ui.color("Public IP:", :cyan)
      object_fields << public_ip
      object_fields << ui.color("Environment:", :cyan)
      object_fields << (config[:environment] || '_default')
      object_fields << ui.color("Run List:", :cyan)
      object_fields << config[:run_list].join(', ')

      puts "\n"
      puts ui.list(object_fields, :uneven_columns_across, 2)
      puts "\n"

      bootstrap(server, public_ip).run
    end

    def fetch_server_fqdn(ip_addr)
        require 'resolv'
        Resolv.getname(ip_addr)
    end

    def is_image_windows?
        template_name = locate_config_value(:cloudstack_template)
        template = connection.get_template(template_name, locate_config_value(:cloudstack_zone))
        template = connection.get_iso(template_name, locate_config_value(:cloudstack_zone)) unless template
        if !template
          ui.error("Template: #{template_name} does not exist, sander")
          exit 1
        end
        return template['ostypename'].scan('Windows').length > 0
    end

    def validate_options
      unless locate_config_value :cloudstack_template
        ui.error "Cloudstack template not specified"
        exit 1
      end
      @windows_image = is_image_windows?
      @windows_platform = is_platform_windows?

      unless locate_config_value :cloudstack_service
        ui.error "Cloudstack service offering not specified"
        exit 1
      end
      if config[:bootstrap]
        if locate_config_value(:bootstrap_protocol) == 'ssh'
          identity_file = locate_config_value :identity_file
          ssh_user = locate_config_value :ssh_user
          ssh_password = locate_config_value :ssh_password
          unless identity_file || (ssh_user && ssh_password) || locate_config_value(:cloudstack_password)
            ui.error("You must specify either an ssh identity file or an ssh user and password")
            exit 1
          end
          @bootstrap_protocol = 'ssh'
        elsif locate_config_value(:bootstrap_protocol) == 'winrm'
          if not @windows_image
            ui.error("Only Windows Images support WinRM protocol for bootstrapping.")
            exit 1
          end
          winrm_user = locate_config_value :winrm_user
          winrm_password = locate_config_value :winrm_password
          winrm_transport = locate_config_value :winrm_transport
          winrm_port = locate_config_value :winrm_port
          unless (winrm_user && winrm_transport && winrm_port) && (locate_config_value(:cloudstack_password) || winrm_password)
            ui.error("WinRM User, Password, Transport and Port are compulsory parameters")
            exit 1
          end
          @bootstrap_protocol = 'winrm'
        end
      end
    end

    def find_or_create_public_ip(server, connection)
      nic = connection.get_server_default_nic(server) || {}
      if (config[:public_ip] == false)
        nic['ipaddress']
      else
        puts("\nAllocate ip address, create forwarding rules")
        ip_address = connection.associate_ip_address(server['zoneid'], locate_config_value(:cloudstack_networks))
        puts("\nAllocated IP Address: #{ip_address['ipaddress']}")
        Chef::Log.debug("IP Address Info: #{ip_address}")

        if locate_config_value :static_nat
          Chef::Log.debug("Enabling static NAT for IP Address : #{ip_address['ipaddress']}")
          connection.enable_static_nat(ip_address['id'], server['id'])
        end
        create_port_forwarding_rules(ip_address, server['id'], connection)
        create_ip_forwarding_rules(ip_address, connection)
        create_firewall_rules(ip_address, connection)
        ip_address['ipaddress']
      end
    end

    def create_port_forwarding_rules(ip_address, server_id, connection)
      Chef::Log.debug("Creating IP Forwarding Rule")
      rules = locate_config_value(:port_rules) || []
      if config[:bootstrap]
        if @bootstrap_protocol == 'ssh'
          rules += ["#{locate_config_value(:ssh_port)}"] #SSH Port
        elsif @bootstrap_protocol == 'winrm'
          rules +=[locate_config_value(:winrm_port)]
        else
          puts("\nUnsupported bootstrap protocol : #{@bootstrap_protocol}")
          exit 1
        end
      end
      return if rules.empty?
      rules.each do |rule|
        args = rule.split(':')
        public_port = args[0]
        private_port = args[1] || args[0]
        protocol = args[2] || "TCP"
        if locate_config_value :static_nat
          Chef::Log.debug("Creating IP Forwarding Rule for
            #{ip_address['ipaddress']} with protocol: #{protocol}, public port: #{public_port}")
          connection.create_ip_fwd_rule(ip_address['id'], protocol, public_port, public_port)
        else
          Chef::Log.debug("Creating Port Forwarding Rule for #{ip_address['id']} with protocol: #{protocol},
            public port: #{public_port} and private port: #{private_port} and server: #{server_id}")
          connection.create_port_forwarding_rule(ip_address['id'], private_port, protocol, public_port, server_id)
        end
      end
    end

    def create_ip_forwarding_rules(ip_address, connection)
      Chef::Log.debug("Creating IP Forwarding Rule")
      rules = locate_config_value(:ipfwd_rules)
      return unless rules
      rules.each do |rule|
        args = rule.split(':')
        startport = args[0]
        endport = args[1] || args[0]
        protocol = args[2] || "TCP"
        if locate_config_value :static_nat
          Chef::Log.debug("Creating IP Forwarding Rule for
              #{ip_address['ipaddress']} with protocol: #{protocol}, startport: #{startport}, endport: #{endport}")
          connection.create_ip_fwd_rule(ip_address['id'], protocol, startport, endport)
        end
      end
    end

    def create_firewall_rules(ip_address, connection)
      Chef::Log.debug("Creating Firewall Rule")
      rules = locate_config_value(:fw_rules)
      return unless rules
      icmptype={
        '0' => {'code' => [0]},
        '8' => {'code' => [0]},
        '3' => {'code' => [0, 1]}
      }
      rules.each do |rule|
        args = rule.split(':')
        protocol = args[0]
        cidr_list = (args[1].nil? || args[1].length == 0) ? "0.0.0.0/0" : args[1]
        startport = args[2]
        endport = args[3] || args[2]
        if protocol == "ICMP"
          icmptype.each do |type, value|
            value['code'].each do |code_id|
              Chef::Log.debug("Creating Firewall Rule for
                #{ip_address['ipaddress']} with protocol: #{protocol}, icmptype: #{type}, icmpcode: #{code_id}, cidrList: #{cidr_list}")
              connection.create_firewall_rule(ip_address['id'], protocol, type, code_id, cidr_list)
            end
          end
        else
          Chef::Log.debug("Creating Firewall Rule for
            #{ip_address['ipaddress']} with protocol: #{protocol}, startport: #{startport}, endport: #{endport}, cidrList: #{cidr_list}")
          connection.create_firewall_rule(ip_address['id'], protocol, startport, endport, cidr_list)
        end
      end
    end

    def tcp_test_winrm(hostname, port)
      TCPSocket.new(hostname, port)
      return true
      rescue SocketError
        sleep 2
        false
      rescue Errno::ETIMEDOUT
        false
      rescue Errno::EPERM
        false
      rescue Errno::ECONNREFUSED
        sleep 2
        false
      rescue Errno::EHOSTUNREACH
        sleep 2
        false
      rescue Errno::ENETUNREACH
        sleep 2
        false
    end

    #noinspection RubyArgCount,RubyResolve
    def is_ssh_open?(ip)
      s = Socket.new(Socket::AF_INET, Socket::SOCK_STREAM, 0)
      sa = Socket.sockaddr_in(locate_config_value(:ssh_port), ip)

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

    def is_platform_windows?
      return RUBY_PLATFORM.scan('w32').size > 0
    end

    def bootstrap(server, public_ip)
      if @windows_image
        Chef::Log.debug("Windows Bootstrapping")
        bootstrap_for_windows_node(server, public_ip)
      else
        Chef::Log.debug("Linux Bootstrapping")
        bootstrap_for_node(server, public_ip)
      end
    end

    def bootstrap_for_windows_node(server, fqdn)
      if locate_config_value(:bootstrap_protocol) == 'winrm'
        bootstrap = Chef::Knife::BootstrapWindowsWinrm.new
        if locate_config_value(:kerberos_realm)
          #Fetch AD/WINS based fqdn if any for Kerberos-based Auth
          private_ip_address = connection.get_server_default_nic(server)["ipaddress"]
          fqdn = locate_config_value(:fqdn) || fetch_server_fqdn(private_ip_address)
        end
        bootstrap.name_args = [fqdn]
        bootstrap.config[:winrm_user] = locate_config_value(:winrm_user) || 'Administrator'
        locate_config_value(:cloudstack_password) ? bootstrap.config[:winrm_password] = server['password'] : bootstrap.config[:winrm_password] = locate_config_value(:winrm_password)
        bootstrap.config[:winrm_transport] = locate_config_value(:winrm_transport)
        bootstrap.config[:winrm_port] = locate_config_value(:winrm_port)
      elsif locate_config_value(:bootstrap_protocol) == 'ssh'
        bootstrap = Chef::Knife::BootstrapWindowsSsh.new
        if locate_config_value(:cloudstack_password)
          bootstrap.config[:ssh_user] = locate_config_value(:ssh_user) || 'Administrator'
        else
          bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
        end
        locate_config_value(:cloudstack_password) ? bootstrap.config[:ssh_password] = server['password'] : bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
        bootstrap.config[:ssh_port] = locate_config_value(:ssh_port)
        bootstrap.config[:identity_file] = locate_config_value(:identity_file)
        bootstrap.config[:no_host_key_verify] = locate_config_value(:no_host_key_verify)
      else
        ui.error("Unsupported Bootstrapping Protocol. Supported : winrm, ssh")
        exit 1
      end
      bootstrap.config[:chef_node_name] = config[:chef_node_name] || server['id']
      bootstrap.config[:encrypted_data_bag_secret] = config[:encrypted_data_bag_secret]
      bootstrap.config[:encrypted_data_bag_secret_file] = config[:encrypted_data_bag_secret_file]
      bootstrap_common_params(bootstrap)
    end

    def bootstrap_common_params(bootstrap)
      bootstrap.config[:run_list] = config[:run_list]
      bootstrap.config[:prerelease] = config[:prerelease]
      bootstrap.config[:bootstrap_version] = locate_config_value(:bootstrap_version)
      bootstrap.config[:distro] = locate_config_value(:distro)
      bootstrap.config[:template_file] = locate_config_value(:template_file)
      bootstrap.config[:first_boot_attributes] = locate_config_value(:first_boot_attributes)
      bootstrap.config[:environment] = locate_config_value(:environment)
      bootstrap
    end

    def bootstrap_for_node(server,fqdn)
      bootstrap = Chef::Knife::Bootstrap.new
      bootstrap.name_args = [fqdn]
      if locate_config_value(:cloudstack_password)
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user) || 'root'
      else
        bootstrap.config[:ssh_user] = locate_config_value(:ssh_user)
      end
      locate_config_value(:cloudstack_password) ? bootstrap.config[:ssh_password] = server['password'] : bootstrap.config[:ssh_password] = locate_config_value(:ssh_password)
      bootstrap.config[:ssh_port] = locate_config_value(:ssh_port) || 22
      bootstrap.config[:identity_file] = locate_config_value(:identity_file)
      bootstrap.config[:chef_node_name] = locate_config_value(:chef_node_name) || server["name"]
      bootstrap.config[:use_sudo] = true unless locate_config_value(:ssh_user) == 'root'

      # may be needed for vpc_mode
      bootstrap.config[:host_key_verify] = config[:host_key_verify]
      bootstrap_common_params(bootstrap)
    end

  end
end
