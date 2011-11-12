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

module KnifeCloudstack
  class CsStackCreate < Chef::Knife

    attr_accessor :current_stack

    deps do
      require 'chef/json_compat'
      require 'chef/mash'
      require 'chef/search/query'
      require 'chef/knife/node_run_list_remove'
      require 'net/ssh'
      require 'net/ssh/multi'
      require 'knife-cloudstack/connection'
      Chef::Knife::Ssh.load_deps
      Chef::Knife::NodeRunListRemove.load_deps
      KnifeCloudstack::CsServerCreate.load_deps
    end

    banner "knife cs stack create JSON_FILE (options)"

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

    def run
      file_path = File.expand_path(@name_args.first)
      unless File.exist?(file_path) then
        ui.error "Stack file '#{file_path}' not found. Please check the path."
        exit 1
      end

      data = File.read file_path
      stack = Chef::JSONCompat.from_json data
      create_stack stack

      #puts "Stack: #{stack.inspect}"
    end

    def connection
      if (!@connection) then
        url = locate_config_value(:cloudstack_url)
        api_key = locate_config_value(:cloudstack_api_key)
        secret_key = locate_config_value(:cloudstack_secret_key)
        @connection = CloudstackClient::Connection.new(url, api_key, secret_key)
      end
      @connection
    end

    def create_stack(stack)
      @current_stack = Mash.new(stack)
      current_stack[:servers].each do |server|
        if server[:name]

          # create server(s)
          names = server[:name].split(/[\s,]+/)
          names.each do |n|
            s = Mash.new(server)
            s[:name] = n
            create_server(s)
          end

        end

        # execute actions
        run_actions server[:actions]
      end

      print_local_hosts
    end

    def create_server(server)

      cmd = KnifeCloudstack::CsServerCreate.new([server[:name]])

      # configure and run command
      # TODO: validate parameters
      cmd.config[:ssh_user] = config[:ssh_user]
      cmd.config[:ssh_password] = config[:ssh_password]
      cmd.config[:ssh_port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
      cmd.config[:identity_file] = config[:identity_file]
      cmd.config[:cloudstack_template] = server[:template] if server[:template]
      cmd.config[:cloudstack_service] = server[:service] if server[:service]
      cmd.config[:cloudstack_zone] = server[:service] if server[:zone]
      cmd.config[:cloudstack_networks] = server[:networks].split(/[\s,]+/) if server[:networks]
      cmd.config[:run_list] = server[:run_list].split(/[\s,]+/) if server[:run_list]
      cmd.config[:port_rules] = server[:port_rules].split(/[\s,]+/) if server[:port_rules]
      if current_stack[:environment]
        cmd.config[:environment] = current_stack[:environment]
        Chef::Config[:environment] = current_stack[:environment]
      end

      cmd.run_with_pretty_exceptions

    end

    def run_actions(actions)
      puts "\n"
      ui.msg("Processing actions...")
      sleep 1 # pause for e.g. chef solr indexing
      actions ||= []
      actions.each do |cmd|
        cmd ||= {}
        cmd.each do |name, args|
          case name
            when 'knife_ssh'
              knife_ssh_action(*args)
            when 'http_request'
              http_request(args)
            when 'run_list_remove'
              run_list_remove(*args)
            when 'sleep'
              dur = args || 5
              sleep dur
          end
        end
      end

    end

    def search_nodes(query, attribute=nil)
      if get_environment
        query = "(#{query})" + " AND chef_environment:#{get_environment}"
      end

      Chef::Log.debug("Searching for nodes: #{query}")

      q = Chef::Search::Query.new
      nodes = Array(q.search(:node, query))

      # the array of nodes is the first item in the array returned by the search
      if nodes.length > 1
        nodes = nodes.first || []
      end

      # return attribute values instead of nodes
      if attribute
        nodes.map do |node|
          node[attribute.to_s]
        end
      else
        nodes
      end
    end

    def knife_ssh(host_list, command)

      ssh = Chef::Knife::Ssh.new
      ssh.name_args = [host_list, command]
      ssh.config[:ssh_user] = config[:ssh_user]
      ssh.config[:ssh_password] = config[:ssh_password]
      ssh.config[:ssh_port] = Chef::Config[:knife][:ssh_port] || config[:ssh_port]
      ssh.config[:identity_file] = config[:identity_file]
      ssh.config[:manual] = true
      ssh.config[:no_host_key_verify] = config[:no_host_key_verify]
      ssh
    end

    def knife_ssh_with_password_auth(host_list, command)
      ssh = knife_ssh(host_list, command)
      ssh.config[:identity_file] = nil
      ssh.config[:ssh_password] = ssh.get_password
      ssh
    end

    def knife_ssh_action(query, command)

      public_ips = find_public_ips(query)
      return if public_ips.nil? || public_ips.empty?
      host_list = public_ips.join(' ')

      ssh = knife_ssh(host_list, command)
      begin
        ssh.run
      rescue Net::SSH::AuthenticationFailed
        unless config[:ssh_password]
          puts "Failed to authenticate #{config[:ssh_user]} - trying password auth"
          ssh = knife_ssh_with_password_auth(host_list, command)
          ssh.run
        end
      end

    end

    def http_request(url)
      match_data = /\$\{([a-zA-Z0-9-]+)\}/.match url
      if match_data
        server_name = match_data[1]
        ip = public_ip_for_host(server_name)
        url = url.sub(/\$\{#{server_name}\}/, ip)
      end


      puts "HTTP Request: #{url}"
      puts `curl -s -m 5 #{url}`
    end

    def run_list_remove(query, entry)
      nodes = search_nodes(query)
      return unless nodes

      nodes.each do |n|
        cmd = Chef::Knife::NodeRunListRemove.new([n.name, entry])
        cmd.run_with_pretty_exceptions
      end
    end

    def find_public_ips(query)
      hostnames = search_nodes(query, 'hostname')
      puts "Found hostnames: #{hostnames.inspect}"
      ips = hostnames.map { |h|
        public_ip_for_host h
      }
      ips.compact.uniq
    end

    def public_ip_for_host(name)
      return nil unless name
      @public_ip_cache ||= {}

      if !@public_ip_cache[name] then
        server = connection.get_server(name)
        return nil unless server

        ip = connection.get_server_public_ip(server)
        @public_ip_cache[name] = ip if ip
      end

      @public_ip_cache[name]
    end

    def get_environment
      current_stack[:environment]
    end

    def destroy_all(domain, excludes=[])
      servers = connection.list_servers || []
      servers.each do |s|
        excluded = false
        excludes.each { |val|
          if s['name'] =~ /#{val}/ then
            excluded = true
            next
          end
        }
        next if excluded
        nodename = "#{s['name']}.#{domain}"
        system "knife cs server delete #{s['name']} -y"
        system "knife client delete #{nodename} -y"
        system "knife node delete #{nodename} -y"
      end
    end

    def print_local_hosts
      hosts = []
      current_stack[:servers].each do |server|
        next unless server[:local_hosts]
        name = server[:name].split(' ').first
        ip = public_ip_for_host(name)
        server[:local_hosts].each { |host|
          hostname = host.sub(/\$\{environment\}/, get_environment)
          hosts << "#{ip}    #{hostname}"
        }
      end
      unless hosts.empty?
        puts "\nAdd this to your /etc/hosts file:"
        puts hosts.join("\n")
      end
    end

    def locate_config_value(key)
      key = key.to_sym
      Chef::Config[:knife][key] || config[key]
    end

  end
end
