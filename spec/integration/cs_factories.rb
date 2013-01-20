# -*- coding: utf-8 -*-
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.m

require  File.expand_path(File.dirname(__FILE__) +'/cs')
# require  File.expand_path(File.dirname(__FILE__) +'/models//knife_parameters')
require "securerandom"

FactoryGirl.define do

	factory :csKnifeParams, class: KnifeParams do
		server_url                       "-s"                                          # Chef Server URL
	  server_url_l                     "--server-url"                                # Chef Server URL
	  api_client_key                   "-k"                                          # API Client Key
	  api_client_key_l                 "--key"                                       # API Client Key
		colored_optput                   "--[no-]color"                                # Use colored output, defaults to enabled
		config_file                      "-c"                                          # The configuration file to use
	  config_file_l                    "--config"                                    # The configuration file to use
	  defaults                         "--defaults"                                  # Accept default values for all questions
	  disable_editing                  "-d"                                          # Do not open EDITOR, just accept the data as is
	  disable_editing_l                "--disable-editing"                           # Do not open EDITOR, just accept the data as is
	  editor                           "-e"                                          # Set the editor to use for interactive commands
	  editor_l                         "--editor"                                    # Set the editor to use for interactive commands
	  environment                      "-E"                                          # Set the Chef environment
	  environment_l                    "--environment"                               # Set the Chef environment
	  format                           "-F"                                          # Which format to use for output
	  format_l                         "--format"                                    # Which format to use for output
	  identity_file                    "-i"                                          # The SSH identity file used for authentication
	  identity_file_l                  "--identity-file"                             # The SSH identity file used for authentication
	  user                             "-u"                                          # API Client Username
	  user_l                           "--user"                                      # API Client Username
	  pre_release                      "--prerelease"                                # Install the pre-release chef gems
	  print_after                      "--print-after"                               # Show the data after a destructive operation
	  verbose                          "-V"                                          # More verbose output. Use twice for max verbosity
	  verbose_l                        "--verbose"                                   # More verbose output. Use twice for max verbosity
	  version_chef                     "-v"                                          # Show chef version
	  version_chef_l                   "--version"                                   # Show chef version
	  say_yes_to_all_prompts           "-y"                                          # Say yes to all prompts for confirmation
	  say_yes_to_all_prompts_l         "--yes"                                       # Say yes to all prompts for confirmation
	  help                             "-h"                                          # Show help
	  help_l                           "--help"                                      # Show help
	end

	factory :csKnifeCommands, class: CSKnifeCommands do
    cmd_list_hosts                 		"knife cs hosts"                     	# Knife command for host list
  	cmd_list_network               		"knife cs network list"               # Knife command for network list
	  cmd_create_server               	"knife cs server create"              # Knife command for creating a server
	  cmd_delete_server               	"knife cs server delete"              # Knife command for deleting a server
	  cmd_list_server                 	"knife cs server list"                # Knife command for listing servers
	  cmd_reboot_server                	"knife cs server reboot"              # Knife command for server reboot
	  cmd_start_server                 	"knife cs server start"               # Knife command for server start
	  cmd_stop_server                 	"knife cs server stop"                # Knife command for server start
	  cmd_list_service                 	"knife cs service list"               # Knife command for listing service
	  cmd_create_stack                 	"knife cs stack create"              	# Knife command for creating stack
	  cmd_delete_stack                 	"knife cs stack delete"               # Knife command for deleting stack
	  cmd_list_template                	"knife cs template list"              # Knife command for listing template
	  cmd_list_zone                			"knife cs zone list"                  # Knife command for listing zone
  end

  factory :csHostsParameters, class: CSKnifeHostsParameters, parent: :csKnifeParams do
		cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		               		"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
  end

  factory :csNetworkListParameters, class: CSKnifeNetworkListParameters , parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
  end

  factory :csServerCreateParameters, class: CSKnifeServerCreateParameters , parent: :csKnifeParams do
  	bootstrap_protocol               	"--bootstrap-protocol"                        # Protocol to bootstrap windows servers. options: winrm/ssh
		bootstrap_version                	"--bootstrap-version"                         # The version of Chef to install
		trust_file                       	"-f"                                          # The Certificate Authority (CA) trust file used for SSL transport
	  trust_file_l                     	"--ca-trust-file"                             # The Certificate Authority (CA) trust file used for SSL transport
		node_name                        	"-N"                                          # The Chef node name for your new node
	  node_name_l                      	"--node-name"                                 # The Chef node name for your new node
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  networks 		              				"-W"                      										# Comma separated list of CloudStack network names
	  networks_l 		              			"--networks"					                      	# Comma separated list of CloudStack network names
	  cs_project_name 		        			"--cloudstack-project"                        # Cloudstack Project in which to create server
	  service 		              				"-S"					                      					# The CloudStack service offering name
	  service_l 		              			"--service"					                      		# The CloudStack service offering name
	  template 		              				"-T"					                      					# The CloudStack template for the server
	  template_l 		              			"--template"					                      	# The CloudStack template for the server
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	  zone 		               						"-Z"                    											# The CloudStack zone for the server
	  zone_l 		               					"--zone"                    									# The CloudStack zone for the server
	  distro                           	"-d"                                          # Bootstrap a distro using a template; default is 'chef-full'
	  distro_l                         	"--distro"                                    # Bootstrap a distro using a template; default is 'chef-full'
	  fqdn 															"--fqdn"                       								# FQDN which Kerberos Understands (only for Windows Servers)
	  keytab_file                      	"-i"                                          # The Kerberos keytab file used for authentication
	  keytab_file_l                    	"--keytab-file"                               # The Kerberos keytab file used for authentication
	  kerberos_realm                   	"-R"                            							# The Kerberos realm used for authentication
	  kerberos_realm_l                 	"--kerberos-realm"                            # The Kerberos realm used for authentication
	  kerberos_service                 	"-S"                                          # The Kerberos service used for authentication
	  kerberos_service_l               	"--kerberos-service"                          # The Kerberos service used for authentication
	  no_bootstrap                  		"--no-bootstrap"                             	# Disable Chef bootstrap
	  no_host_key_verify               	"--no-host-key-verify"                        # Disable host key verification
	  port_rules                       	"-p"                                      		# Comma separated list of port forwarding rules, e.g. '25,53:4053,80:8080:TCP'
	  port_rules_l                     	"--port-rules"                                # Comma separated list of port forwarding rules, e.g. '25,53:4053,80:8080:TCP'
	  public_ip                    			"--[no-]public-ip"                            # Allocate a public IP for this server
	  run_list                         	"-r"                                          # Comma separated list of roles/recipes to apply
	  run_list_l                       	"--run-list"                                  # Comma separated list of roles/recipes to apply
	  ssh_password_l                   	"--ssh-password"                          		# The ssh password
	  ssh_port_l        								"--ssh-port"              										# The ssh port
	  ssh_username_l                   	"--ssh-user"                              		# The ssh username
	  static_nat_l											"--static-nat"                 								# Support Static NAT
	  template_file                    	"--template-file"                         		# Full path to location of template to use
	  use_hhtp_ssl_l										"--[no-]use-http-ssl"          								# Support HTTP
	  winrm_password                   	"-P"                                          # The WinRM password
	  winrm_password_l                 	"--winrm-password"                            # The WinRM password
	  winrm_port                       	"-p"                                          # The WinRM port, by default this is 5985
	  winrm_port_l                     	"--winrm-port"                                # The WinRM port, by default this is 5985
	  winrm_transport                  	"-t"                                          # The WinRM transport type.  valid choices are [ssl, plaintext]
	  winrm_transport_l                	"--winrm-transport"                           # The WinRM transport type.  valid choices are [ssl, plaintext]
	  winrm_user                       	"-x"                                          # The WinRM username
	  winrm_user_l                     	"--winrm-user"                                # The WinRM username
  end

	factory :csServerDeleteParameters, class: CSKnifeServerDeleteParameters , parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_project_name 		        			"-P"									                        # Cloudstack Project in which to create server
	  cs_project_name_l 		        		"--cloudstack-project"                        # Cloudstack Project in which to create server
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	  use_hhtp_ssl_l										"--[no-]use-http-ssl"          								# Support HTTP
	end

	factory :csServerListParameters, class: CSKnifeServerListParameters , parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_project_name 		        			"--cloudstack-project"                        # Cloudstack Project in which to create server
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	  use_hhtp_ssl_l										"--[no-]use-http-ssl"          								# Support HTTP
	end

	factory :csServerRebootParameters, class: CSKnifeServerRebootParameters , parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	end

	factory :csServerStartParameters, class: CSKnifeServerStartParameters , parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	end

	factory :csServerStopParameters, class: CSKnifeServerStopParameters, parent: :csKnifeParams do
		server_url                       	"-s"                                          # Chef Server URL
	  server_url_l                     	"--server-url"                                # Chef Server URL
	  api_client_key                   	"-k"                                          # API Client Key
	  api_client_key_l                 	"--key"                                       # API Client Key
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  force_l														"--force" 				                     				# Force stop the VM. The caller knows the VM is stopped.
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	end

	factory :csServiceListParameters, class: CSKnifeServiceListParameters, parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	end

	factory :csStackCreateParameters, class: CSKnifeStackCreateParameters, parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       			# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                         	# Your CloudStack API key
	  cs_secret_key       			        "-K"                                       			# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                      	# Your CloudStack secret key
	  cs_url 		               					"-U"             											         	# The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				 	# The CloudStack endpoint URL
	  ssh_password                   		"-P"                          								# The ssh password
	  ssh_password_l                   	"--ssh-password"                          		# The ssh password
	  ssh_username                   		"-x"                              						# The ssh username
	  ssh_username_l                   	"--ssh-user"                              		# The ssh username
	end

	factory :csStackDeleteParameters, class: CSKnifeStackDeleteParameters, parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       			# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                         	# Your CloudStack API key
	  cs_secret_key       			        "-K"                                       			# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                      	# Your CloudStack secret key
	  cs_url 		               					"-U"             											         	# The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				 	# The CloudStack endpoint URL
	end

	factory :csTemplateListParameters, class: CSKnifeTemplateListParameters, parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_project_name 		        			"-P"									                        # Cloudstack Project in which to create server
	  cs_project_name_l 		        		"--cloudstack-project"                        # Cloudstack Project in which to create server
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	  filter 														"-L"              														# The template search filter. Default is 'featured'
	  filter_l 													"--filter"              											# The template search filter. Default is 'featured'
	end

	factory :csZoneListParameters, class: CSKnifeZoneListParameters, parent: :csKnifeParams do
	  cs_api_key       			          	"-A"                                       		# Your CloudStack API key
	  cs_api_key_l 		                	"--cloudstack-api-key"                        # Your CloudStack API key
	  cs_secret_key       			        "-K"                                       		# Your CloudStack secret key
	  cs_secret_key_l 		              "--cloudstack-secret-key"                     # Your CloudStack secret key
	  cs_url 		               					"-U"             											        # The CloudStack endpoint URL
	  cs_url_l 		               				"--cloudstack-url"                    				# The CloudStack endpoint URL
	end

  model_obj_server_create           = (CSKnifeServerCreateParameters.new)
  cs_server_create_params_factory  	= FactoryGirl.build(:csServerCreateParameters)
	cs_server_delete_params_factory  	= FactoryGirl.build(:csServerDeleteParameters)
  cs_server_list_params_factory  		= FactoryGirl.build(:csServerListParameters)

  properties_file = File.expand_path(File.dirname(__FILE__) + "/properties/credentials.yml")
  properties = File.open(properties_file) { |yf| YAML::load(yf) }
  valid_api_key 		= properties["credentials"]["api_key"]
  valid_secret_key 	= properties["credentials"]["secret_key"]
  valid_url					= properties["credentials"]["endpoint_url"]
  valid_template_file_path            = model_obj_server_create.get_template_file_path


  # Base Factory for server create
  factory :csServerCreateBase, class: CSKnifeServerCreateParameters do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
    node_name 			"#{cs_server_create_params_factory.node_name} "     	+ name_of_the_node
    cs_api_key 			"#{cs_server_create_params_factory.cs_api_key} "   		+ "#{valid_api_key}"
    cs_secret_key 	"#{cs_server_create_params_factory.cs_secret_key} " 	+ "#{valid_secret_key}"
    cs_url      		"#{cs_server_create_params_factory.cs_url} "        	+ "#{valid_url}"
    service_l 		  "#{cs_server_create_params_factory.service_l} "       + "'Small Instance'"
	  template 		  	"#{cs_server_create_params_factory.template} "      	+ "'CentOS 5.3(64-bit) no GUI (vSphere)'"
	  zone 		  			"#{cs_server_create_params_factory.zone} "      			+ "ADV-VSPHERE-DC"
	  ssh_username_l  "#{cs_server_create_params_factory.ssh_username_l} "  + "root"
	  ssh_password_l  "#{cs_server_create_params_factory.ssh_password_l} "  + "password"
	  networks 				"#{cs_server_create_params_factory.networks} "  			+	"Clogeny-Local-Network"
	  use_hhtp_ssl_l	"--no-use-http-ssl"
	  distro          "#{cs_server_create_params_factory.distro} "  				+	"chef-full"
  end

  # Base Factory for server create
  factory :csServerDeleteBase, class: CSKnifeServerDeleteParameters do
    cs_api_key 			"#{cs_server_create_params_factory.cs_api_key} "   		+ "#{valid_api_key}"
    cs_secret_key 	"#{cs_server_create_params_factory.cs_secret_key} " 	+ "#{valid_secret_key}"
    cs_url      		"#{cs_server_create_params_factory.cs_url} "        	+ "#{valid_url}"
    use_hhtp_ssl_l	"--no-use-http-ssl"
  end

  # Base Factory for server create
  factory :csServerListBase, class: CSKnifeServerListParameters do
    cs_api_key 			"#{cs_server_create_params_factory.cs_api_key} "   		+ "#{valid_api_key}"
    cs_secret_key 	"#{cs_server_create_params_factory.cs_secret_key} " 	+ "#{valid_secret_key}"
    cs_url      		"#{cs_server_create_params_factory.cs_url} "        	+ "#{valid_url}"
    use_hhtp_ssl_l	"--no-use-http-ssl"
  end

	# Test Case: OP_KCP_1, CreateServerWithDefaults
  factory :csServerCreateWithDefaults, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     + name_of_the_node
  end


  # Test Case: OP_KCP_2, CreateServerInSpecificNetwork
  factory :csServerCreateInSpecificNetwork, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     		+ name_of_the_node
  	networks 					"#{cs_server_create_params_factory.networks} "  			 	+	"Clogeny-Local-Network"
  end

  # Test Case: OP_KCP_3, CreateServerOfDifferentServiceOfferingSize
  factory :csServerCreateOfDifferentServiceOfferingSize, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "   + name_of_the_node
  	service_l 				"#{cs_server_create_params_factory.service_l} "   + "'Tiny Instance'"
  end

  # Test Case: OP_KCP_4, CreateServerWithTCPPortList
  factory :csServerCreateWithTCPPortList, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     + name_of_the_node
  	port_rules    		"#{cs_server_create_params_factory.port_rules} "    + "'80:80:TCP,443:8433:TCP'"
  end

  # Test Case: OP_KCP_5, CreateServerWithUDPPortList
  factory :csServerCreateWithUDPPortList, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     + name_of_the_node
  	port_rules    		"#{cs_server_create_params_factory.port_rules} "    + "'80:80:UDP,443:8433:UDP'"
  end

  # Test Case: OP_KCP_6, CreateServerWithTCPPortListStaticNat
  factory :csServerCreateWithTCPPortListStaticNat, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     	+ name_of_the_node
  	port_rules    		"#{cs_server_create_params_factory.port_rules} "    	+ "'80:80:TCP,443:8433:TCP'"
  	static_nat_l  		"#{cs_server_create_params_factory.static_nat_l} "
  end


  # Test Case: OP_KCP_7, CreateServerWithUDPPortListStaticNat
  factory :csServerCreateWithUDPPortListStaticNat, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     + name_of_the_node
  	port_rules    		"#{cs_server_create_params_factory.port_rules} "    + "'161:161:UDP,111:111:UDP'"
  	static_nat_l  		"#{cs_server_create_params_factory.static_nat_l} "
  end

  # Test Case: OP_KCP_8, CreateServerWithSpecificProject
  factory :csServerCreateWithSpecificProject, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     			+ name_of_the_node
  	cs_project_name 	"#{cs_server_create_params_factory.cs_project_name} "     + "Project_Opscode"
  end

  # Test Case: OP_KCP_9, CreateServerWithSpecificProjectAndSpecificNetwork
  factory :csServerCreateWithSpecificProjectAndSpecificNetwork, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     					+ name_of_the_node
  	networks 					"#{cs_server_create_params_factory.networks} "  							+	"Opscode"
  	cs_project_name 	"#{cs_server_create_params_factory.cs_project_name} "     		+ "Project_Opscode"
  end

  # Test Case: OP_KCP_10, CreateServerInNonExistentNetwork
  factory :csServerCreateInNonExistentNetwork, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     + name_of_the_node
  	networks 					"#{cs_server_create_params_factory.networks} "  		+	"Non-Existent-Network"
  end

  # Test Case: OP_KCP_11, CreateServerInNonExistentProject
  factory :csServerCreateInNonExistentProject, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     			+ name_of_the_node
  	cs_project_name 	"#{cs_server_create_params_factory.cs_project_name} "     + "Non-Existent-Project"
  end

  # Test Case: OP_KCP_12, CreateServerInProjectAndnonExistentNetwork
  factory :csServerCreateInProjectAndnonExistentNetwork, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     		+ name_of_the_node
  	networks 					"#{cs_server_create_params_factory.networks} "  				+	"Non-Existent-Network"
  	cs_project_name 	"#{cs_server_create_params_factory.cs_project_name} "  	+ "Non-Existent-Project"
  end

  # Test Case: OP_KCP_13, CreateServerInProjectAndNetworkThatDoesBelong
  factory :csServerCreateInProjectAndNetworkThatDoesBelong, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     			+ name_of_the_node
  	networks 					"#{cs_server_create_params_factory.networks} "  					+	"Clogeny-Local-Network"
  	cs_project_name 	"#{cs_server_create_params_factory.cs_project_name} "     + "Project_Opscode"
  end

  # Test Case: OP_KCP_14, CreateServerWithStaticIP
  factory :csServerCreateWithStaticIP, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     			+ name_of_the_node
  	static_nat_l      "#{cs_server_create_params_factory.static_nat_l} "
  end

  # Test Case: OP_KCP_15, CreateServerWithInvalidSSHPassword
  factory :csServerCreateWithInvalidSSHPassword, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     	+ name_of_the_node
	  ssh_password_l  	"#{cs_server_create_params_factory.ssh_password_l} "  + "invalidPassword"
  end


  # Test Case: OP_KCP_17, DeleteServerThatDoesNotExist
  factory :csServerDeleteNonExistent, parent: :csServerDeleteBase do
  end

  # Test Case: OP_KCP_18, DeleteServerWithoutOSDisk
  factory :csServerDeleteWithoutOSDisk, parent: :csServerDeleteBase do
  end

  # Test Case: OP_KCP_19, DeleteServerWithOSDisk
  factory :csServerDeleteWithOSDisk, parent: :csServerDeleteBase do
  end

  # Test Case: OP_KCP_20, DeleteMutipleServers
  factory :csServerDeleteMutiple, parent: :csServerDeleteBase do
  end

  # Test Case: OP_KCP_21, ListServerEmpty
  factory :csServerListEmpty, parent: :csServerListBase do
  end


  # Test Case: OP_KCP_22, ListServerNonEmpty
  factory :csServerListNonEmpty, parent: :csServerListBase do
  end

  # Test Case: OP_KCP_23, DeleteServerPurge
  factory :csServerDeletePurge, parent: :csServerDeleteBase do
  	# purge          "#{cs_server_create_params_factory.purge} "
  end

  # Test Case: OP_KCP_24, DeleteServerDontPurge
  factory :csServerDeleteDonrPurge, parent: :csServerDeleteBase do
  end

  # Test Case: OP_KCP_25, CreateServerWithValidNodeName
  factory :csServerCreateWithValidNodeName, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     + name_of_the_node
  end

  # Test Case: OP_KCP_26, CreateServerWithRoleAndRecipe
  factory :csServerCreateWithRoleAndRecipe, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "  + name_of_the_node
  	run_list      		"#{cs_server_create_params_factory.run_list} "   + "recipe[build-essential], role[webserver]"
  end

  # Test Case: OP_KCP_27, CreateServerWithInvalidRole
  factory :csServerCreateWithInvalidRole, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "  + name_of_the_node
  	run_list      		"#{cs_server_create_params_factory.run_list} "   + "recipe[build-essential], role[invalid-role]"
  end

  # Test Case: OP_KCP_28, CreateServerWithInvalidRecipe
  factory :csServerCreateWithInvalidRecipe, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "  + name_of_the_node
  	run_list      		"#{cs_server_create_params_factory.run_list} "   + "recipe[invalid-recipe]"
  end

  # Test Case: OP_KCP_29, CreateWindowsServerWithWinRMBasicAuth
  factory :csWindowsServerWithWinRMBasicAuth, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "    					+ name_of_the_node
  	template 		  		"#{cs_server_create_params_factory.template} "      				+ "'Win2k8-Basic-Auth'"
    winrm_password    "#{cs_server_create_params_factory.winrm_password} "       	+ "winRmPassw0rd"
    winrm_port        "#{cs_server_create_params_factory.winrm_port} "           	+ "5985"
    winrm_transport   "#{cs_server_create_params_factory.winrm_transport} "      	+ "plaintext"
    winrm_user        "#{cs_server_create_params_factory.winrm_user} "           	+ "winRmUser"
    template_file     "#{cs_server_create_params_factory.template_file} "        	+ "#{valid_template_file_path}"
  end

  # Test Case: OP_KCP_30, CreateWindowsServerWithSSHAuth
  factory :csWindowsServerCreateWithSSHAuth, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "     	+ name_of_the_node
  	template 		  		"#{cs_server_create_params_factory.template} "      	+ "'Win2k8-Basic-Auth'"
  	ssh_username_l  	"#{cs_server_create_params_factory.ssh_username_l} "  + "Administrator"
    ssh_password_l  	"#{cs_server_create_params_factory.ssh_password_l} "  + "azure!Pass0rd"
  	template_file   	"#{cs_server_create_params_factory.template_file} " 	+ "#{valid_template_file_path}"
  end

  # Test Case: OP_KCP_31, CreateLinuxServerWithWinRM
  factory :csWindowsServerWithWinRM, parent: :csServerCreateBase do
  	name_of_the_node  = "cs#{SecureRandom.hex(4)}"
  	node_name 				"#{cs_server_create_params_factory.node_name} "    					+ name_of_the_node
    winrm_password    "#{cs_server_create_params_factory.winrm_password} "       	+ "winRmPassw0rd"
    winrm_port        "#{cs_server_create_params_factory.winrm_port} "           	+ "5985"
    winrm_transport   "#{cs_server_create_params_factory.winrm_transport} "      	+ "plaintext"
    winrm_user        "#{cs_server_create_params_factory.winrm_user} "           	+ "winRmUser"
    template_file     "#{cs_server_create_params_factory.template_file} "        	+ "#{valid_template_file_path}"
  end

end
