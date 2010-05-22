require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VMTest < Test::Unit::TestCase
  setup do
    @mock_vm = mock("vm")

    @persisted_vm = mock("persisted_vm")

    @env = mock_environment
    @env.stubs(:vm).returns(@persisted_vm)

    Net::SSH.stubs(:start)
  end

  context "being an action runner" do
    should "be an action runner" do
      vm = Vagrant::VM.new(:env => @env)
      assert vm.is_a?(Vagrant::Actions::Runner)
    end
  end

  context "finding a VM" do
    should "return return an uncreated VM object if the VM is not found" do
      VirtualBox::VM.expects(:find).returns(nil)
      result = Vagrant::VM.find("foo")
      assert result.is_a?(Vagrant::VM)
      assert !result.created?
    end

    should "return a Vagrant::VM object for that VM if found" do
      VirtualBox::VM.expects(:find).with("foo").returns("bar")
      result = Vagrant::VM.find("foo", mock_environment)
      assert result.is_a?(Vagrant::VM)
      assert_equal "bar", result.vm
    end
  end

  context "vagrant VM instance" do
    setup do
      @vm_name = "foo"
      @vm = Vagrant::VM.new(:env => @env, :vm => @mock_vm, :vm_name => @vm_name)
      @mock_vm.stubs(:uuid).returns("foo")
    end

    context "checking if created" do
      should "return true if the VM object is not nil" do
        @vm.stubs(:vm).returns(:foo)
        assert @vm.created?
      end

      should "return false if the VM object is nil" do
        @vm.stubs(:vm).returns(nil)
        assert !@vm.created?
      end
    end

    context "accessing the SSH object" do
      setup do
        # Reset this to nil to force the reload
        @vm.instance_variable_set(:@ssh, nil)

        @ssh = mock("ssh")
        Vagrant::SSH.stubs(:new).returns(@ssh)
      end

      should "load it the first time" do
        Vagrant::SSH.expects(:new).with(@vm.env).once.returns(@ssh)
        @vm.ssh
        @vm.ssh
        @vm.ssh
      end

      should "use the same value once its loaded" do
        result = @vm.ssh
        assert_equal result, @vm.ssh
      end
    end

    context "loading associated system" do
      should "error and exit if system is not specified" do
        @vm.env.config.vm.system = nil

        @vm.expects(:error_and_exit).with(:system_unspecified).once
        @vm.load_system!
      end

      context "with a class" do
        class FakeSystemClass
          def initialize(vm); end
        end

        should "initialize class if given" do
          @vm.env.config.vm.system = Vagrant::Systems::Linux

          @vm.expects(:error_and_exit).never
          @vm.load_system!

          assert @vm.system.is_a?(Vagrant::Systems::Linux)
        end

        should "error and exit if class has invalid parent" do
          @vm.env.config.vm.system = FakeSystemClass
          @vm.expects(:error_and_exit).with(:system_invalid_class, :system => @vm.env.config.vm.system.to_s).once
          @vm.load_system!
        end
      end

      context "with a symbol" do
        should "initialize proper symbols" do
          valid = {
            :linux => Vagrant::Systems::Linux
          }

          valid.each do |symbol, klass|
            @vm.env.config.vm.system = symbol
            @vm.expects(:error_and_exit).never
            @vm.load_system!

            assert @vm.system.is_a?(klass)
            assert_equal @vm, @vm.system.vm
          end
        end

        should "error and exit with invalid symbol" do
          @vm.env.config.vm.system = :shall_never_exist
          @vm.expects(:error_and_exit).with(:system_unknown_type, :system => @vm.env.config.vm.system.to_s).once
          @vm.load_system!
        end
      end
    end

    context "uuid" do
      should "call UUID on VM object" do
        uuid = mock("uuid")
        @mock_vm.expects(:uuid).once.returns(uuid)
        assert_equal uuid, @vm.uuid
      end

      should "return nil if vm is nil" do
        @vm.expects(:vm).returns(nil)
        assert @vm.uuid.nil?
      end
    end

    context "reloading" do
      should "load the same VM and set it" do
        new_vm = mock("vm")
        VirtualBox::VM.expects(:find).with(@mock_vm.uuid).returns(new_vm)
        @vm.reload!
        assert_equal new_vm, @vm.vm
      end
    end

    context "packaging" do
      should "queue up the actions and execute" do
        out_path = mock("out_path")
        action_seq = sequence("actions")
        @vm.expects(:add_action).with(Vagrant::Actions::VM::Export).once.in_sequence(action_seq)
        @vm.expects(:add_action).with(Vagrant::Actions::VM::Package, out_path, []).once.in_sequence(action_seq)
        @vm.expects(:execute!).in_sequence(action_seq)
        @vm.package(out_path)
      end
    end

    context "upping" do
      should "execute the up action" do
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Up).once
        @vm.up
      end
    end

    context "halting" do
      should "execute the halt action" do
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Halt, false).once
        @vm.halt
      end

      should "force if specified" do
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Halt, true).once
        @vm.halt(true)
      end
    end

    context "reloading action" do
      should "execute the reload action" do
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Reload).once
        @vm.reload
      end
    end

    context "provisioning" do
      should "execute the provision action" do
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Provision).once
        @vm.provision
      end
    end

    context "destroying" do
      should "execute the down action" do
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Down).once
        @vm.destroy
      end
    end

    context "suspending" do
      should "execute the suspend action" do
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Suspend).once
        @vm.suspend
      end
    end

    context "resuming" do
      should "execute the resume action" do
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Resume).once
        @vm.resume
      end
    end

    context "starting" do
      setup do
        @mock_vm.stubs(:running?).returns(false)
      end

      should "not do anything if the VM is already running" do
        @mock_vm.stubs(:running?).returns(true)
        @vm.expects(:execute!).never
        @vm.start
      end

      should "execute the start action" do
        @vm.expects(:execute!).once.with(Vagrant::Actions::VM::Start)
        @vm.start
      end
    end
  end
end
