# -*- coding: utf-8 -*-
# Author:: Chirag Jog (<chirag@clogeny.com>)
# Copyright:: Copyright (c) 2012 Opscode, Inc.
require File.expand_path(File.dirname(__FILE__) + '/cs_factories')

require 'knife_cloud_tests'
require 'knife_cloud_tests/knifeutils'
require 'knife_cloud_tests/matchers'
#require File.expand_path(File.dirname(__FILE__) +'../../../spec_helper')
require "securerandom"

RSpec.configure do |config|
  FactoryGirl.find_definitions
end

def prepare_create_srv_cmd_cs_cspec(server_create_factory)
  cmd = "#{cmds_cs.cmd_create_server} " +
    strip_out_command_key("#{server_create_factory.node_name}")  +
    " "+
    prepare_knife_command(server_create_factory)
  return cmd
end

# Common method to run create server test cases

def run_cs_cspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised,  run_list_cmd = true, run_del_cmd = true)
  context "" do
    instance_name = "instance_name"
    cmd_out = ""
    context "#{test_context}" do
      let(:server_create_factory){ FactoryGirl.build(factory_to_be_exercised) }
      # let(:instance_name){ strip_out_command_key("#{server_create_factory.node_name}") }
      let(:command) { prepare_create_srv_cmd_cs_cspec(server_create_factory) }
      after(:each){instance_name = strip_out_command_key("#{server_create_factory.node_name}")}
      context "#{test_case_scene}" do
        it "#{test_run_expect[:status]}" do
          match_status(test_run_expect)
        end
      end
    end

    if run_list_cmd
      context "list server after #{test_context} " do
        let(:grep_cmd) { "| grep -e #{instance_name}" }
        let(:command) { prepare_list_srv_cmd_cs_lspec(srv_list_base_fact_cs)}
        after(:each){cmd_out = "#{cmd_stdout}"}
        it "should succeed" do
          match_status({:status => "should succeed"})
        end
      end
    end

    if run_del_cmd
      context "delete-purge server after #{test_context} #{test_case_scene}" do
        let(:command) { "#{cmds_cs.cmd_delete_server}" + " " +
                        "#{instance_name}" +
                        " " +
                        prepare_knife_command(srv_del_base_fact_cs) +
                        " -y"}
        it "should succeed" do
          match_status({:status => "should succeed"})
        end
      end
    end

  end
end


# Method to prepare cs create server command

def prepare_list_srv_cmd_cs_lspec(factory)
  cmd = "#{cmds_cs.cmd_list_server} " +
  prepare_knife_command(factory)
  return cmd
end

# Common method to run create server test cases

def run_cs_lspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:server_list_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_list_srv_cmd_cs_lspec(server_list_factory) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect}" do
        match_status({:status => test_run_expect})
      end
    end
  end
end


def create_srv_cs_dspec(server_create_factory)
  cmd = "#{cmds_cs_dspec.cmd_create_server} " +
  prepare_knife_command(server_create_factory)
  shell_out_command(cmd, "creating instance...")
end

def create_srvs_cs_dspec(count, os_disk = "")
  for server_count in 0..count
    node_name_local  = "#{srv_create_params_fact_cs.node_name} "  + "csnode#{SecureRandom.hex(4)}"
    if os_disk != ""
      os_disk_name_local  = "#{srv_create_params_fact_cs.os_disk_name} "     + "#{os_disk}"
      fact =  FactoryGirl.build(:csServerCreateWithDefaults,
        node_name: node_name_local,
        os_disk_name: os_disk_name_local)
    else
      fact =  FactoryGirl.build(:csServerCreateWithDefaults,
        node_name: node_name_local)
    end
    instances.push fact
    create_srv_cs_dspec(fact)
  end
  return instances
end

def find_srv_ids_cs_dspec(instances)
  instance_ids = []
  instances.each do |instance|
    instance_ids.push strip_out_command_key("#{instance.node_name}")
  end
  return instance_ids
end

# Method to prepare cs create server command

def prepare_del_srv_cmd_cs_dspec(factory, instances)
  cmd ="#{cmds_cs_dspec.cmd_delete_server}" + " " +
  "#{prepare_list_srv_ids_cs_dspec(instances)}" + " " + prepare_knife_command(factory) + " -y"
  return cmd
end

def prepare_del_srv_cmd_purge_cs_dspec(factory, instances)
  node_names = "-N"
  instances.each do |instance|
    node_names = node_names + " " + strip_out_command_key("#{instance.node_name}")
  end

  cmd ="#{cmds_cs_dspec.cmd_delete_server}" + " " +
  "#{prepare_list_srv_ids_cs_dspec(instances)}" + " " +  node_names + " -P " + prepare_knife_command(factory) + " -y"
  return cmd
end

def prepare_del_srv_cmd_non_exist_cs_dspec(factory)
  cmd ="#{cmds_cs_dspec.cmd_delete_server}" + " " +
  "1234567890" + " " + prepare_knife_command(factory) + " -y"
  return cmd
end

def prepare_list_srv_ids_cs_dspec(instances)
  instances_to_be_deleted = ""
  instance_ids = find_srv_ids_cs_dspec(instances)
  instance_ids.each do |instance|
    instances_to_be_deleted = instances_to_be_deleted + " " + "#{instance}"
  end
  return instances_to_be_deleted
end

# Common method to run create server test cases

def run_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised, test_case_type="")
  case test_case_type
      when "delete"
        srv_del_test_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      when "delete_purge"
        srv_del_test_purge_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      when "delete_multiple"
        srv_del_test_mult_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      when "delete_non_existent"
        srv_del_test_non_exist_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      when "delete_with_os_disk"
        srv_del_test_os_disk_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
      else
  end
end

def srv_del_test_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:instances) { [] }
    before(:each) {create_srvs_cs_dspec(0)}
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_cs_dspec(server_delete_factory, instances) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

def srv_del_test_purge_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:instances) { [] }
    before(:each) {create_srvs_cs_dspec(0)}
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_cs_dspec(server_delete_factory, instances) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end


def srv_del_test_mult_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:instances) { [] }
    before(:each) {create_srvs_cs_dspec(1)}
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_cs_dspec(server_delete_factory, instances) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

def srv_del_test_non_exist_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_non_exist_cs_dspec(server_delete_factory) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

def srv_del_test_os_disk_cs_dspec(test_context, test_case_scene, test_run_expect, factory_to_be_exercised)
  context "#{test_context}" do
    let(:instances) { [] }
    before(:each) {create_srvs_cs_dspec(0, "diskname")}
    let(:server_delete_factory){ FactoryGirl.build(factory_to_be_exercised) }
    let(:command) { prepare_del_srv_cmd_cs_dspec(server_delete_factory, instances) }
    after(:each) {puts "Test case completed!"}
    context "#{test_case_scene}" do
      it "#{test_run_expect[:status]}" do
        match_status(test_run_expect)
      end
    end
  end
end

describe 'knife cloudstack' do
  include RSpec::KnifeUtils
  # before(:all) { load_factory_girl }
  before(:all) { load_knife_config }

  let(:cmds_cs) { FactoryGirl.build(:csKnifeCommands) }
  let(:srv_del_base_fact_cs) {FactoryGirl.build(:csServerDeleteBase) }
  let(:srv_list_base_fact_cs) {FactoryGirl.build(:csServerListBase) }
  let(:srv_create_params_fact_cs){FactoryGirl.build(:csServerCreateParameters)}

  expected_params = {
                     :status => "should succeed",
                     :stdout => nil,
                     :stderr => nil
                   }

  # Test Case: OP_KCP_1, CreateServerWithDefaults
  run_cs_cspec("server create", "with all default parameters", expected_params, :csServerCreateWithDefaults, true)

  # Test Case: OP_KCP_2, CreateServerInSpecificNetwork
  run_cs_cspec("server create", "in specifc network", expected_params, :csServerCreateInSpecificNetwork, false)

  # Test Case: OP_KCP_3, CreateServerOfDifferentServiceOfferingSize
  run_cs_cspec("server create", "of different service offerings", expected_params, :csServerCreateOfDifferentServiceOfferingSize, true)

  # Test Case: OP_KCP_4, CreateServerWithTCPPortList
  run_cs_cspec("server create", "with TCP port list", expected_params, :csServerCreateWithTCPPortList, false)

  # Test Case: OP_KCP_5, CreateServerWithUDPPortList
  run_cs_cspec("server create", "with UDP port list", expected_params, :csServerCreateWithUDPPortList, false)

  # Test Case: OP_KCP_6, CreateServerWithTCPPortListStaticNat
  run_cs_cspec("server create", "with TCP port list (static NAT)", expected_params, :csServerCreateWithTCPPortListStaticNat, false)

  # Test Case: OP_KCP_7, CreateServerWithUDPPortListStaticNat
  run_cs_cspec("server create", "with UDP port (static NAT)", expected_params, :csServerCreateWithUDPPortListStaticNat, false)

  # Test Case: OP_KCP_8, CreateServerWithSpecificProject
  run_cs_cspec("server create", "with specific project", expected_params, :csServerCreateWithSpecificProject, true)

  # Test Case: OP_KCP_9, CreateServerWithSpecificProjectAndSpecificNetwork
  run_cs_cspec("server create", "with specific project and specific network", expected_params, :csServerCreateWithSpecificProjectAndSpecificNetwork, false)

  # Test Case: OP_KCP_14, CreateServerWithStaticIP
  run_cs_cspec("server create", "with static IP", expected_params, :csServerCreateWithStaticIP, false)

  # Test Case: OP_KCP_25, CreateServerWithValidNodeName
  run_cs_cspec("server create", "with valid node name", expected_params, :csServerCreateWithValidNodeName, true)

  # Test Case: OP_KCP_26, CreateServerWithRoleAndRecipe
  run_cs_cspec("server create", "with role and recipe", expected_params, :csServerCreateWithRoleAndRecipe, false)


  # Test Case: OP_KCP_29, CreateWindowsServerWithWinRMBasicAuth
  run_cs_cspec("windows server create", "with RM Basic auth", expected_params, :csWindowsServerWithWinRMBasicAuth, true)

  # Test Case: OP_KCP_30, CreateWindowsServerWithSSHAuth
  run_cs_cspec("windows server create", "with SSH auth", expected_params, :csWindowsServerCreateWithSSHAuth, false)

  # Test Case: OP_KCP_18, DeleteServerWithoutOSDisKC
  run_cs_dspec("server delete", "without OS disk", expected_params, :csServerDeleteWithoutOSDisk, "delete")

  # Test Case: OP_KCP_19, DeleteServerWithOSDiKC
  run_cs_dspec("server delete", "with OS disk", expected_params, :csServerDeleteWithOSDisk, "delete_with_os_disk")

  # Test Case: OP_KCP_20, DeleteMutipleServeKC
  run_cs_dspec("server delete", "command for multiple servers", expected_params, :csServerDeleteMultiple, "delete_multiple")

  # Test Case: OP_KCP_23, DeleteServerPurKC
  run_cs_dspec("server delete", "with purge option", expected_params, :csServerDeletePurge, "delete_purge")

  # Test Case: OP_KCP_24, DeleteServerDontPurge
  run_cs_dspec("server delete", "woth no purge option", expected_params, :csServerDeleteDontPurge, "delete")

  expected_params = {
                     :status => "should return empty list",
                     :stdout => nil,
                     :stderr => nil
                   }

  # Test Case: OP_KCP_21, ListServerEmpty
  run_cs_lspec("server list", "for no instances", "should return empty list", :csServerListEmpty)

    expected_params = {
                     :status => "should fail",
                     :stdout => nil,
                     :stderr => nil
                   }

  # Test Case: OP_KCP_15, CreateServerWithInvalidSSHPassword
  run_cs_cspec("server create", "with invalid SSH password", expected_params, :csServerCreateWithInvalidSSHPassword, false, false)

  # Test Case: OP_KCP_27, CreateServerWithInvalidRole
  # FIXME need to write a custom matcher to validate invalid role
  run_cs_cspec("server create", "with invalid role", expected_params, :csServerCreateWithInvalidRole, false)

  # Test Case: OP_KCP_28, CreateServerWithInvalidRecipe
  # FIXME need to write a custom matcher to validate invalid recipe
  run_cs_cspec("server create", "with invalid recipe", expected_params, :csServerCreateWithInvalidRecipe, false)

  # Test Case: OP_KCP_31, CreateLinuxServerWithWinRM
  run_cs_cspec("server create", "with Win RM", expected_params, :csWindowsServerWithWinRM, false)

  # Test Case: OP_KCP_17, DeleteServerThatDoesNotEKCist
  run_cs_dspec("server delete", "with non existent server", expected_params, :csServerDeleteNonExistent, "delete_non_existent")

  # Test Case: OP_KCP_10, CreateServerInNonExistentNetwork
  run_cs_cspec("server create", "in non existent network", expected_params, :csServerCreateInNonExistentNetwork, false, false)

  # Test Case: OP_KCP_11, CreateServerInNonExistentProject
  run_cs_cspec("server create", "in non existent project", expected_params, :csServerCreateInNonExistentProject, false, false)

  # Test Case: OP_KCP_12, CreateServerInProjectAndnonExistentNetwork
  run_cs_cspec("server create", "in non existent project and non existent network", expected_params, :csServerCreateInProjectAndnonExistentNetwork, false)

  # Test Case: OP_KCP_13, CreateServerInProjectAndNetworkThatDoesBelong
  run_cs_cspec("server create", "in a project and a network that does not belong to the project", expected_params, :csServerCreateInProjectAndNetworkThatDoesBelong, false, false)



end
