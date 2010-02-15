require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VMTest < Test::Unit::TestCase
  setup do
    @mock_vm = mock("vm")
    mock_config

    @persisted_vm = mock("persisted_vm")
    Vagrant::Env.stubs(:persisted_vm).returns(@persisted_vm)

    Net::SSH.stubs(:start)
  end

  context "callbacks" do
    setup do
      @vm = Vagrant::VM.new(@mock_vm)
    end

    should "not invoke callback on actions which don't respond to it" do
      action = mock("action")
      action.stubs(:respond_to?).with(:foo).returns(false)
      action.expects(:foo).never

      assert_nothing_raised do
        @vm.actions << action
        @vm.invoke_callback(:foo)
      end
    end

    should "invoke callback on actions which do respond to the method" do
      action = mock("action")
      action.expects(:foo).once

      @vm.actions << action
      @vm.invoke_callback(:foo)
    end

    should "collect all the results and return them as an array" do
      result = []
      3.times do |i|
        action = mock("action#{i}")
        action.expects(:foo).returns("foo#{i}").once

        @vm.actions << action
        result << "foo#{i}"
      end

      assert_equal result, @vm.invoke_callback(:foo)
    end
  end

  context "actions" do
    setup do
      @vm = Vagrant::VM.new(@mock_vm)
    end

    should "be empty initially" do
      assert @vm.actions.empty?
    end

    should "initialize the action when added" do
      action_klass = mock("action_class")
      action_inst = mock("action_inst")
      action_klass.expects(:new).once.returns(action_inst)
      @vm.add_action(action_klass)
      assert_equal 1, @vm.actions.length
    end

    should "run #prepare on all actions, then #execute!" do
      action_seq = sequence("action_seq")
      actions = []
      5.times do |i|
        action = mock("action#{i}")

        @vm.actions << action
        actions << action
      end

      [:prepare, :execute!].each do |method|
        actions.each do |action|
          action.expects(method).once.in_sequence(action_seq)
        end
      end

      @vm.execute!
    end

    should "run actions on class method execute!" do
      vm = mock("vm")
      execute_seq = sequence("execute_seq")
      Vagrant::VM.expects(:new).returns(vm).in_sequence(execute_seq)
      vm.expects(:add_action).with("foo").in_sequence(execute_seq)
      vm.expects(:execute!).once.in_sequence(execute_seq)

      Vagrant::VM.execute!("foo")
    end
  end

  context "vagrant up" do
    should "create a Vagrant::VM instance and call create" do
      inst = mock("instance")
      inst.expects(:create).once
      Vagrant::VM.expects(:new).returns(inst)
      Vagrant::VM.up
    end
  end

  context "finding a VM" do
    should "return nil if the VM is not found" do
      VirtualBox::VM.expects(:find).returns(nil)
      assert_nil Vagrant::VM.find("foo")
    end

    should "return a Vagrant::VM object for that VM otherwise" do
      VirtualBox::VM.expects(:find).with("foo").returns("bar")
      result = Vagrant::VM.find("foo")
      assert result.is_a?(Vagrant::VM)
      assert_equal "bar", result.vm
    end
  end

  context "vagrant VM instance" do
    setup do
      @vm = Vagrant::VM.new(@mock_vm)
    end

    context "creating" do
      should "create the VM in the proper order" do
        prov = mock("prov")
        create_seq = sequence("create_seq")
        Vagrant::Provisioning.expects(:new).with(@vm).in_sequence(create_seq).returns(prov)
        @vm.expects(:import).in_sequence(create_seq)
        @vm.expects(:persist).in_sequence(create_seq)
        @vm.expects(:setup_mac_address).in_sequence(create_seq)
        @vm.expects(:forward_ports).in_sequence(create_seq)
        @vm.expects(:setup_shared_folders).in_sequence(create_seq)
        @vm.expects(:start).in_sequence(create_seq)
        @vm.expects(:mount_shared_folders).in_sequence(create_seq)
        prov.expects(:run).in_sequence(create_seq)
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
        Vagrant::SSH.expects(:up?).once.returns(true)
        @vm.start(0)
      end

      should "repeatedly ping the SSH port and return false with no response" do
        seq = sequence('pings')
        Vagrant::SSH.expects(:up?).times(Vagrant.config[:ssh][:max_tries].to_i - 1).returns(false).in_sequence(seq)
        Vagrant::SSH.expects(:up?).once.returns(true).in_sequence(seq)
        assert @vm.start(0)
      end

      should "ping the max number of times then just return" do
        Vagrant::SSH.expects(:up?).times(Vagrant.config[:ssh][:max_tries].to_i).returns(false)
        assert !@vm.start(0)
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
        Vagrant::Env.expects(:persist_vm).with(@mock_vm).once
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

    context "forwarding ports" do
      should "create a port forwarding for the VM" do
        # TODO: Test the actual port value to make sure it has the
        # correct attributes
        forwarded_ports = mock("forwarded_ports")
        forwarded_ports.expects(:<<)
        @mock_vm.expects(:forwarded_ports).returns(forwarded_ports)
        @mock_vm.expects(:save).with(true).once
        @vm.forward_ports
      end
    end

    context "shared folders" do
      setup do
        @mock_vm = mock("mock_vm")
        @vm = Vagrant::VM.new(@mock_vm)
      end

      should "not have any shared folders initially" do
        assert @vm.shared_folders.empty?
      end

      should "be able to add shared folders" do
        @vm.share_folder("foo", "from", "to")
        assert_equal 1, @vm.shared_folders.length
      end

      should "be able to clear shared folders" do
        @vm.share_folder("foo", "from", "to")
        assert !@vm.shared_folders.empty?
        @vm.shared_folders(true)
        assert @vm.shared_folders.empty?
      end

      should "add all shared folders to the VM with 'setup_shared_folders'" do
        @vm.share_folder("foo", "from", "to")
        @vm.share_folder("bar", "bfrom", "bto")

        share_seq = sequence("share_seq")
        shared_folders = mock("shared_folders")
        shared_folders.expects(:<<).in_sequence(share_seq).with() { |sf| sf.name == "foo" && sf.hostpath == "from" }
        shared_folders.expects(:<<).in_sequence(share_seq).with() { |sf| sf.name == "bar" && sf.hostpath == "bfrom" }
        @mock_vm.stubs(:shared_folders).returns(shared_folders)
        @mock_vm.expects(:save).with(true).once

        @vm.setup_shared_folders
      end

      should "mount all shared folders to the VM with `mount_shared_folders`" do
        @vm.share_folder("foo", "from", "to")
        @vm.share_folder("bar", "bfrom", "bto")

        mount_seq = sequence("mount_seq")
        ssh = mock("ssh")
        @vm.shared_folders.each do |name, hostpath, guestpath|
          ssh.expects(:exec!).with("sudo mkdir -p #{guestpath}").in_sequence(mount_seq)
          ssh.expects(:exec!).with("sudo mount -t vboxsf #{name} #{guestpath}").in_sequence(mount_seq)
          ssh.expects(:exec!).with("sudo chown #{Vagrant.config.ssh.username} #{guestpath}").in_sequence(mount_seq)
        end
        Vagrant::SSH.expects(:execute).yields(ssh)

        @vm.mount_shared_folders
      end
    end

    context "saving the state" do
      should "check if a VM is saved" do
        @mock_vm.expects(:saved?).returns("foo")
        assert_equal "foo", @vm.saved?
      end

      should "save state with errors raised" do
        @mock_vm.expects(:save_state).with(true).once
        @vm.save_state
      end
    end

    context "creating a new vm with a specified disk storage location" do
      should "error and exit of the vm is not powered off" do
        # Exit does not prevent method from proceeding in test, so we must set expectations
        vm = move_hd_expectations
        @mock_vm.expects(:powered_off?).returns(false)
        vm.expects(:error_and_exit)
        vm.move_hd
      end

      should "create assign a new disk image, and delete the old one" do
        vm = move_hd_expectations
        @mock_vm.expects(:powered_off?).returns(true)
        vm.move_hd
      end

      def move_hd_expectations
        image, hd = mock('image'), mock('hd')

        Vagrant.config[:vm].expects(:hd_location).at_least_once.returns('/locations/')
        image.expects(:clone).with(Vagrant.config[:vm][:hd_location] + 'foo', Vagrant.config[:vm][:disk_image_format], true).returns(image)
        image.expects(:filename).twice.returns('foo')
        image.expects(:destroy)

        hd.expects(:image).twice.returns(image)
        hd.expects(:image=).with(image)

        @mock_vm.expects(:save)

        vm = Vagrant::VM.new(@mock_vm)
        vm.expects(:hd).times(3).returns(hd)
        vm
      end
    end
  end

  context "packaging a vm" do
    should "dump the three necessary files to a tar in the current working dir" do
      location = FileUtils.pwd
      name = 'vagrant'
      new_dir = File.join(location, name)
      @mock_vm.expects(:export).with(File.join(new_dir, "#{name}.ovf"))
      FileUtils.expects(:mkpath).with(new_dir).returns(new_dir)
      FileUtils.expects(:rm_r).with(new_dir)
      Tar.expects(:open)

      # TODO test whats passed to the open tar.append_tree
      assert_equal Vagrant::VM.new(@mock_vm).package(name, location), "#{new_dir}.box"
    end
  end
end
