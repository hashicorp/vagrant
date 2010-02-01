require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VMTest < Test::Unit::TestCase
  setup do
    @mock_vm = mock("vm")
    Hobo.config!(hobo_mock_config)

    @persisted_vm = mock("persisted_vm")
    Hobo::Env.stubs(:persisted_vm).returns(@persisted_vm)

    Net::SSH.stubs(:start)
  end

  context "hobo ssh" do
    setup do
      Hobo::SSH.stubs(:connect)
    end

    should "require a persisted VM" do
      Hobo::Env.expects(:require_persisted_vm).once
      Hobo::VM.ssh
    end

    should "connect to SSH" do
      Hobo::SSH.expects(:connect).once
      Hobo::VM.ssh
    end
  end

  context "hobo down" do
    setup do
      @persisted_vm.stubs(:destroy)
    end

    should "require a persisted VM" do
      Hobo::Env.expects(:require_persisted_vm).once
      Hobo::VM.down
    end

    should "destroy the persisted VM and the VM image" do
      @persisted_vm.expects(:destroy).once
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

  context "finding a VM" do
    should "return nil if the VM is not found" do
      VirtualBox::VM.expects(:find).returns(nil)
      assert_nil Hobo::VM.find("foo")
    end

    should "return a Hobo::VM object for that VM otherwise" do
      VirtualBox::VM.expects(:find).with("foo").returns("bar")
      result = Hobo::VM.find("foo")
      assert result.is_a?(Hobo::VM)
      assert_equal "bar", result.vm
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
        @vm.expects(:start).in_sequence(create_seq)
        @vm.create
      end
    end

    context "destroying" do
      setup do
        @mock_vm.stubs(:running?).returns(false)
      end

      should "destoy the VM along with images" do
        @mock_vm.expects(:destroy).with(:destroy_image => true).once
        @vm.destroy
      end

      should "stop the VM if its running" do
        @mock_vm.expects(:running?).returns(true)
        @mock_vm.expects(:stop).with(true)
        @mock_vm.expects(:destroy).with(:destroy_image => true).once
        @vm.destroy
      end
    end

    context "starting" do
      setup do
        @mock_vm.stubs(:start)
      end

      should "start the VM in headless mode" do
        @mock_vm.expects(:start).with(:headless, true).once
        @vm.start
      end

      should "repeatedly SSH while waiting for the VM to start" do
        ssh_seq = sequence("ssh_seq")
        Net::SSH.expects(:start).once.raises(Errno::ECONNREFUSED).in_sequence(ssh_seq)
        Net::SSH.expects(:start).once.in_sequence(ssh_seq)
        @vm.start
      end

      should "try the max number of times then just return" do
        Net::SSH.expects(:start).times(Hobo.config[:ssh][:max_tries].to_i).raises(Errno::ECONNREFUSED)
        assert !@vm.start
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
      should "create a shared folder with the root folder for the VM" do
        shared_folder = mock("shared_folder")
        shared_folder.stubs(:name=)
        shared_folder.expects(:hostpath=).with(Hobo::Env.root_path).once
        shared_folder_collection = mock("collection")
        shared_folder_collection.expects(:<<).with(shared_folder)
        VirtualBox::SharedFolder.expects(:new).returns(shared_folder)
        @mock_vm.expects(:shared_folders).returns(shared_folder_collection)
        @mock_vm.expects(:save).with(true).once
        @vm.setup_shared_folder
      end
    end
  end
end
