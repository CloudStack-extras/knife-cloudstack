# -*- coding: utf-8 -*-
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.

# require  File.expand_path(File.dirname(__FILE__) +'/knife_parameters')
require 'knife_cloud_tests'

class CSKnifeCommands
  attr_accessor :cmd_list_hosts                 	# "knife cs hosts"                     	# Knife command for host list
  attr_accessor :cmd_list_network               	# "knife cs network list"               # Knife command for network list
  attr_accessor :cmd_create_server               	# "knife cs server create"              # Knife command for creating a server
  attr_accessor :cmd_delete_server               	# "knife cs server delete"              # Knife command for deleting a server
  attr_accessor :cmd_list_server                 	# "knife cs server list"                # Knife command for listing servers
  attr_accessor :cmd_reboot_server                # "knife cs server reboot"              # Knife command for server reboot
  attr_accessor :cmd_start_server                 # "knife cs server start"               # Knife command for server start
  attr_accessor :cmd_stop_server                 	# "knife cs server stop"                # Knife command for server start
  attr_accessor :cmd_list_service                 # "knife cs service list"               # Knife command for listing service
  attr_accessor :cmd_create_stack                 # "knife cs stack create"              	# Knife command for creating stack
  attr_accessor :cmd_delete_stack                 # "knife cs stack delete"               # Knife command for deleting stack
  attr_accessor :cmd_list_template                # "knife cs template list"              # Knife command for listing template
  attr_accessor :cmd_list_zone                		# "knife cs zone list"                  # Knife command for listing zone
end

module CSBaseKeys
  attr_accessor :cs_api_key                       # "-A"                                          # Your CloudStack API key
  attr_accessor :cs_api_key_l                     # "--cloudstack-api-key"                        # Your CloudStack API key
  attr_accessor :cs_secret_key                    # "-K"                                          # Your CloudStack secret key
  attr_accessor :cs_secret_key_l                  # "--cloudstack-secret-key"                     # Your CloudStack secret key
  attr_accessor :cs_url                           # "-U"                                          # The CloudStack endpoint URL
  attr_accessor :cs_url_l                         # "--cloudstack-url"                            # The CloudStack endpoint URL
end

class CSKnifeHostsParameters < KnifeParams
  include CSBaseKeys
end

class CSKnifeNetworkListParameters < KnifeParams
  include CSBaseKeys
end

class CSKnifeServerCreateParameters < KnifeParams
  include CSBaseKeys
	attr_accessor :bootstrap_protocol               # "--bootstrap-protocol"                        # Protocol to bootstrap windows servers. options: winrm/ssh
	attr_accessor :bootstrap_version                # "--bootstrap-version"                         # The version of Chef to install
	attr_accessor :trust_file                       # "-f"                                          # The Certificate Authority (CA) trust file used for SSL transport
  attr_accessor :trust_file_l                     # "--ca-trust-file"                             # The Certificate Authority (CA) trust file used for SSL transport
	attr_accessor :node_name                        # "-N"                                          # The Chef node name for your new node
  attr_accessor :node_name_l                      # "--node-name"                                 # The Chef node name for your new node
  attr_accessor :networks 		              			# "-W"                      										# Comma separated list of CloudStack network names
  attr_accessor :networks_l 		              		# "--networks"					                      	# Comma separated list of CloudStack network names
  attr_accessor :cs_project_name 		        			# "--cloudstack-project"                        # Cloudstack Project in which to create server
  attr_accessor :service 		              				# "-S"					                      					# The CloudStack service offering name
  attr_accessor :service_l 		              			# "--service"					                      		# The CloudStack service offering name
  attr_accessor :template 		              			# "-T"					                      					# The CloudStack template for the server
  attr_accessor :template_l 		              		# "--template"					                      	# The CloudStack template for the server
  attr_accessor :zone 		               					# "-Z"                    											# The CloudStack zone for the server
  attr_accessor :zone_l 		               				# "--zone"                    									# The CloudStack zone for the server
  attr_accessor :distro                           # "-d"                                          # Bootstrap a distro using a template; default is 'chef-full'
  attr_accessor :distro_l                         # "--distro"                                    # Bootstrap a distro using a template; default is 'chef-full'
  attr_accessor :fqdn 														# "--fqdn"                       								# FQDN which Kerberos Understands (only for Windows Servers)
  attr_accessor :keytab_file                      # "-i"                                          # The Kerberos keytab file used for authentication
  attr_accessor :keytab_file_l                    # "--keytab-file"                               # The Kerberos keytab file used for authentication
  attr_accessor :kerberos_realm                   # "-R"                            							# The Kerberos realm used for authentication
  attr_accessor :kerberos_realm_l                 # "--kerberos-realm"                            # The Kerberos realm used for authentication
  attr_accessor :kerberos_service                 # "-S"                                          # The Kerberos service used for authentication
  attr_accessor :kerberos_service_l               # "--kerberos-service"                          # The Kerberos service used for authentication
  attr_accessor :no_bootstrap                  		# "--no-bootstrap"                             	# Disable Chef bootstrap
  attr_accessor :no_host_key_verify               # "--no-host-key-verify"                        # Disable host key verification
  attr_accessor :port_rules                       # "-p"                                      		# Comma separated list of port forwarding rules, e.g. '25,53:4053,80:8080:TCP'
  attr_accessor :port_rules_l                     # "--port-rules"                                # Comma separated list of port forwarding rules, e.g. '25,53:4053,80:8080:TCP'
  attr_accessor :public_ip                    		# "--[no-]public-ip"                            # Allocate a public IP for this server
  attr_accessor :run_list                         # "-r"                                          # Comma separated list of roles/recipes to apply
  attr_accessor :run_list_l                       # "--run-list"                                  # Comma separated list of roles/recipes to apply
  attr_accessor :ssh_password_l                   # "--ssh-password"                          		# The ssh password
  attr_accessor :ssh_port_l        								# "--ssh-port PORT"              								# The ssh port
  attr_accessor :ssh_username_l                   # "--ssh-user"                              		# The ssh username
  attr_accessor :static_nat_l											# "--static-nat"                 								# Support Static NAT
  attr_accessor :template_file                    # "--template-file"                         		# Full path to location of template to use
  attr_accessor :use_hhtp_ssl_l										# "--[no-]use-http-ssl"          								# Support HTTP
  attr_accessor :winrm_password                   # "-P"                                          # The WinRM password
  attr_accessor :winrm_password_l                 # "--winrm-password"                            # The WinRM password
  attr_accessor :winrm_port                       # "-p"                                          # The WinRM port, by default this is 5985
  attr_accessor :winrm_port_l                     # "--winrm-port"                                # The WinRM port, by default this is 5985
  attr_accessor :winrm_transport                  # "-t"                                          # The WinRM transport type.  valid choices are [ssl, plaintext]
  attr_accessor :winrm_transport_l                # "--winrm-transport"                           # The WinRM transport type.  valid choices are [ssl, plaintext]
  attr_accessor :winrm_user                       # "-x"                                          # The WinRM username
  attr_accessor :winrm_user_l                     # "--winrm-user"                                # The WinRM username

  def user_ssh_dir
      @_user_ssh_dir ||= Dir.mktmpdir
  end

  #FIXME This file should be fetch from a properties/ config file but for now we are placing the file content here
  def get_template_file_name
      return "template.erb"
  end

  # Method used to generate template file for cs windows bootstraps
  # This method fetches the file template file from
  # https://raw.github.com/opscode/knife-windows/master/lib/chef/knife/bootstrap/windows-chef-client-msi.erb

  def get_template_file_path

    # For windows machine do the follwing settings to set the ssl cert
    # download => http://curl.haxx.se/ca/cacert.pem
    # put the downloaded file to desired location, e.g. C:\cacert.pem
    # run command prompt and run => set SSL_CERT_FILE=C:\cacert.pem

    require 'open-uri'
    template_file_path = "#{user_ssh_dir}/" + get_template_file_name
    template_file_data = open("https://raw.github.com/opscode/knife-windows/master/lib/chef/knife/bootstrap/windows-chef-client-msi.erb")
    File.open("#{template_file_path}", 'w') {|f| f.write(template_file_data.read)}
    puts "Creating user cs template file at: " + "#{user_ssh_dir}/template.erb"
    return template_file_path
  end

end


class CSKnifeServerDeleteParameters < KnifeParams
  include CSBaseKeys
  attr_accessor :cs_project_name 		        			# "-P"									                        # Cloudstack Project in which to create server
  attr_accessor :cs_project_name_l 		        		# "--cloudstack-project"                        # Cloudstack Project in which to create server
  attr_accessor :use_hhtp_ssl_l										# "--[no-]use-http-ssl"          								# Support HTTP
end

class CSKnifeServerListParameters < KnifeParams
  include CSBaseKeys
  attr_accessor :cs_project_name 		        			# "--cloudstack-project"                        # Cloudstack Project in which to create server
  attr_accessor :use_hhtp_ssl_l										# "--[no-]use-http-ssl"          								# Support HTTP
end


class CSKnifeServerRebootParameters < KnifeParams
  include CSBaseKeys
end

class CSKnifeServerStartParameters < KnifeParams
  include CSBaseKeys
end

class CSKnifeServerStopParameters < KnifeParams
  include CSBaseKeys
  attr_accessor :force_l													# "--force" 				                     				# Force stop the VM. The caller knows the VM is stopped.
end

class CSKnifeServiceListParameters < KnifeParams
  include CSBaseKeys
end

class CSKnifeStackCreateParameters < KnifeParams
  include CSBaseKeys
  attr_accessor :ssh_password                   	# "-P"                          								# The ssh password
  attr_accessor :ssh_password_l                   # "--ssh-password"                          		# The ssh password
  attr_accessor :ssh_username                   	# "-x"                              						# The ssh username
  attr_accessor :ssh_username_l                   # "--ssh-user"                              		# The ssh username
end

class CSKnifeStackDeleteParameters < KnifeParams
  include CSBaseKeys
end

class CSKnifeTemplateListParameters < KnifeParams
  include CSBaseKeys
  attr_accessor :cs_project_name 		        			# "-P"									                        # Cloudstack Project in which to create server
  attr_accessor :cs_project_name_l 		        		# "--cloudstack-project"                        # Cloudstack Project in which to create server
  attr_accessor :filter 													# "-L"              														# The template search filter. Default is 'featured'
  attr_accessor :filter_l 												# "--filter"              											# The template search filter. Default is 'featured'
  attr_accessor :use_hhtp_ssl_l										# "--[no-]use-http-ssl"          								# Support HTTP
end

class CSKnifeZoneListParameters < KnifeParams
  include CSBaseKeys
end
