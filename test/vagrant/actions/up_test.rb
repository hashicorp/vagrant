require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class UpActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @import = mock_action(Vagrant::Actions::Up)
    mock_config
  end

  context "callbacks" do
    should "call persist and mac address setup before boot" do
      boot_seq = sequence("boot")
      @action.expects(:persist).once.in_sequence(boot_seq)
      @action.expects(:setup_mac_address).once.in_sequence(boot_seq)
      @action.before_boot
    end

    should "setup the root directory shared folder" do
      expected = ["vagrant-root", Vagrant::Env.root_path, Vagrant.config.vm.project_directory]
      assert_equal expected, @action.collect_shared_folders
    end
  end

  context "persisting" do
    should "persist the VM with Env" do
      @vm.stubs(:uuid)
      Vagrant::Env.expects(:persist_vm).with(@vm).once
      @action.persist
    end
  end

  context "setting up MAC address" do
    should "match the mac address with the base" do
      nic = mock("nic")
      nic.expects(:macaddress=).once

      @vm.expects(:nics).returns([nic]).once
      @vm.expects(:save).with(true).once

      @action.setup_mac_address
    end
  end
end
