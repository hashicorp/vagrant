require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VMTest < Test::Unit::TestCase
  setup do
    @mock_vm = mock("vm")
    Hobo.config!(hobo_mock_config)
  end

  context "hobo down" do
    setup do
      @persisted_vm = mock("persisted_vm")
      @persisted_vm.stubs(:destroy)
      Hobo::Env.stubs(:persisted_vm).returns(@persisted_vm)
    end

    should "require a persisted VM" do
      Hobo::Env.expects(:require_persisted_vm).once
      Hobo::VM.down
    end

    should "destroy the persisted VM and the VM image" do
      @persisted_vm.expects(:destroy).with(:destroy_image => true).once
      Hobo::VM.down
    end
  end

  context "hobo up" do
    should "create a Hobo::VM instance and call create" do
      inst = mock("instance")
      inst.expects(:create).once
      Hobo::VM.expects(:new).returns(inst)
      Hobo::VM.up
    end
  end

  context "hobo VM instance" do
    setup do
      @vm = Hobo::VM.new(@mock_vm)
    end

    context "creating" do
      should "create the VM in the proper order" do
        create_seq = sequence("create_seq")
        @vm.expects(:import).in_sequence(create_seq)
        @vm.expects(:persist).in_sequence(create_seq)
        @vm.expects(:setup_mac_address).in_sequence(create_seq)
        @vm.expects(:forward_ssh).in_sequence(create_seq)
        @vm.expects(:setup_shared_folder).in_sequence(create_seq)
        @vm.create
      end
    end

    context "importing" do
      should "call import on VirtualBox::VM with the proper base" do
        VirtualBox::VM.expects(:import).once
        @vm.import
      end

      should "return the VM object" do
        VirtualBox::VM.expects(:import).returns(@mock_vm).once
        assert_equal @mock_vm, @vm.import
      end
    end

    context "persisting" do
      should "persist the VM with Env" do
        @mock_vm.stubs(:uuid)
        Hobo::Env.expects(:persist_vm).with(@mock_vm).once
        @vm.persist
      end
    end

    context "setting up MAC address" do
      should "match the mac address with the base" do
        nic = mock("nic")
        nic.expects(:macaddress=).once

        @mock_vm.expects(:nics).returns([nic]).once
        @mock_vm.expects(:save).with(true).once

        @vm.setup_mac_address
      end
    end

    context "forwarding SSH" do
      should "create a port forwarding for the VM" do
        # TODO: Test the actual port value to make sure it has the
        # correct attributes
        forwarded_ports = mock("forwarded_ports")
        forwarded_ports.expects(:<<)
        @mock_vm.expects(:forwarded_ports).returns(forwarded_ports)
        @mock_vm.expects(:save).with(true).once
        @vm.forward_ssh
      end
    end

    context "setting up the shared folder" do
      # TODO: Since the code actually doesn't do anything yet
    end
  end
end
