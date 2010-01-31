require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VMTest < Test::Unit::TestCase
  setup do
    @vm = mock("vm")
    Hobo.config!(hobo_mock_config)
  end

  context "hobo up" do
    should "create the instance in the proper order" do
      create_seq = sequence("create_seq")
      Hobo::VM.expects(:import).in_sequence(create_seq)
      Hobo::VM.expects(:persist_vm).in_sequence(create_seq)
      Hobo::VM.expects(:setup_mac_address).in_sequence(create_seq)
      Hobo::VM.expects(:forward_ssh).in_sequence(create_seq)
      Hobo::VM.expects(:setup_shared_folder).in_sequence(create_seq)
      Hobo::VM.up
    end
  end

  context "importing" do
    should "call import on VirtualBox::VM with the proper base" do
      VirtualBox::VM.expects(:import).once
      Hobo::VM.import
    end

    should "return the VM object" do
      VirtualBox::VM.expects(:import).returns(@vm).once
      assert_equal @vm, Hobo::VM.import
    end
  end

  context "persisting VM" do
    should "persist the VM with Env" do
      @vm.stubs(:uuid)
      Hobo::Env.expects(:persist_vm).with(@vm).once
      Hobo::VM.persist_vm(@vm)
    end
  end

  context "setting up MAC address" do
    should "match the mac address with the base" do
      nic = mock("nic")
      nic.expects(:macaddress=).once

      @vm.expects(:nics).returns([nic]).once
      @vm.expects(:save).with(true).once

      Hobo::VM.setup_mac_address(@vm)
    end
  end

  context "forwarding SSH" do
    should "create a port forwarding for the VM" do
      # TODO: Test the actual port value to make sure it has the
      # correct attributes
      forwarded_ports = mock("forwarded_ports")
      forwarded_ports.expects(:<<)
      @vm.expects(:forwarded_ports).returns(forwarded_ports)
      @vm.expects(:save).with(true).once
      Hobo::VM.forward_ssh(@vm)
    end
  end

  context "setting up the shared folder" do
    # TODO: Since the code actually doesn't do anything yet
  end
end
