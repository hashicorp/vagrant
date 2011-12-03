require "test_helper"

class VMTest < Test::Unit::TestCase
  setup do
    @env = vagrant_env
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
      result = Vagrant::VM.find("foo", @env)
      assert result.is_a?(Vagrant::VM)
      assert_equal "bar", result.vm
    end
  end

  context "vagrant VM instance" do
    setup do
      @vm_name = "foo"
      @mock_vm = mock("vm")
      @mock_vm.stubs(:running?).returns(false)
      @vm = Vagrant::VM.new(:env => @env, :vm => @mock_vm, :name => @vm_name)
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

    context "setting the VM" do
      setup do
        @raw_vm = mock("vm")
        @raw_vm.stubs(:uuid).returns("foobar")
      end

      should "set the VM" do
        @vm.vm = @raw_vm
        assert_equal @raw_vm, @vm.vm
      end

      should "add the VM to the active list" do
        assert @env.local_data.empty?
        @vm.vm = @raw_vm
        assert_equal @raw_vm.uuid, @env.local_data[:active][@vm.name.to_s]
      end

      should "remove the VM from the active list if nil is given" do
        @env.local_data[:active] = { @vm.name.to_s => "foo" }

        assert @env.local_data[:active].has_key?(@vm.name.to_s) # sanity
        @vm.vm = nil

        # This becomes empty because vm= will commit the local data which
        # actually prunes out the empty values.
        assert @env.local_data.empty?
      end
    end

    context "accessing the SSH object" do
      setup do
        # Reset this to nil to force the reload
        @vm.instance_variable_set(:@ssh, nil)

        @ssh = mock("ssh")
        Vagrant::SSH.stubs(:new).returns(@ssh)
      end

      should "load it the first time, and only load it once" do
        Vagrant::SSH.expects(:new).with(@vm.env).once.returns(@ssh)
        @vm.ssh
        @vm.ssh
        @vm.ssh
      end
    end

    context "loading associated system" do
      should "error and exit if system is not specified" do
        @vm.env.config.vm.system = nil

        assert_raises(Vagrant::Errors::VMSystemError) {
          @vm.load_system!
        }
      end

      should "load the given system if specified" do
        fake_class = Class.new(Vagrant::Systems::Base)

        assert_nothing_raised { @vm.load_system!(fake_class) }
        assert @vm.system.is_a?(fake_class)
      end

      context "with a class" do
        should "initialize class if given" do
          @vm.env.config.vm.system = Vagrant::Systems::Linux

          assert_nothing_raised { @vm.load_system!}
          assert @vm.system.is_a?(Vagrant::Systems::Linux)
        end

        should "raise error if class has invalid parent" do
          @vm.env.config.vm.system = Class.new
          assert_raises(Vagrant::Errors::VMSystemError) {
            @vm.load_system!
          }
        end
      end

      context "with a symbol" do
        should "initialize proper symbols" do
          valid = {
            :linux => Vagrant::Systems::Linux,
            :solaris => Vagrant::Systems::Solaris
          }

          valid.each do |symbol, klass|
            @vm.env.config.vm.system = symbol

            assert_nothing_raised { @vm.load_system! }
            assert @vm.system.is_a?(klass)
            assert_equal @vm, @vm.system.vm
          end
        end

        should "error and exit with invalid symbol" do
          @vm.env.config.vm.system = :shall_never_exist

          assert_raises(Vagrant::Errors::VMSystemError) {
            @vm.load_system!
          }
        end
      end

      context "loading the distro" do
        setup do
          @vm.vm.stubs(:running?).returns(true)
        end

        should "not replace the distro if it is nil" do
          @vm.env.config.vm.system = Class.new(Vagrant::Systems::Base)

          @vm.load_system!
          assert @vm.system.is_a?(@vm.env.config.vm.system)
        end

        should "replace the distro if it is not nil" do
          @vm.env.config.vm.system = Class.new(Vagrant::Systems::Base) do
            def distro_dispatch
              :linux
            end
          end

          @vm.load_system!
          assert @vm.system.is_a?(Vagrant::Systems::Linux)
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
      should "execute the package action" do
        @vm.env.actions.expects(:run).once.with() do |action, options|
          assert_equal :package, action
          assert_equal :bar, options[:foo]
          true
        end

        @vm.package(:foo => :bar)
      end
    end

    context "upping" do
      should "execute the up action" do
        @vm.env.actions.expects(:run).with(:up, nil).once
        @vm.up
      end

      should "forward options to the action sequence" do
        @vm.env.actions.expects(:run).with(:up, :foo => :bar).once
        @vm.up(:foo => :bar)
      end
    end

    context "halting" do
      should "execute the halt action" do
        @vm.env.actions.expects(:run).with(:halt, :foo => :bar).once
        @vm.halt({:foo => :bar})
      end
    end

    context "reloading action" do
      should "execute the reload action" do
        @vm.env.actions.expects(:run).with(:reload).once
        @vm.reload
      end
    end

    context "provisioning" do
      should "execute the provision action" do
        @vm.env.actions.expects(:run).with(:provision).once
        @vm.provision
      end
    end

    context "destroying" do
      should "execute the destroy action" do
        @vm.env.actions.expects(:run).with(:destroy).once
        @vm.destroy
      end
    end

    context "suspending" do
      should "execute the suspend action" do
        @vm.env.actions.expects(:run).with(:suspend).once
        @vm.suspend
      end
    end

    context "resuming" do
      should "execute the resume action" do
        @vm.env.actions.expects(:run).with(:resume).once
        @vm.resume
      end
    end

    context "starting" do
      setup do
        @mock_vm.stubs(:running?).returns(false)
        @mock_vm.stubs(:saved?).returns(false)
        @mock_vm.stubs(:accessible?).returns(true)
      end

      should "not do anything if the VM is already running" do
        @mock_vm.stubs(:running?).returns(true)
        @vm.expects(:execute!).never
        @vm.start
      end

      should "execute the resume action if saved" do
        @mock_vm.expects(:saved?).returns(true)
        @vm.expects(:resume).once
        @vm.env.actions.expects(:run).with(:start, nil).never
        @vm.start
      end

      should "execute the start action" do
        @vm.env.actions.expects(:run).with(:start, nil).once
        @vm.start
      end

      should "forward options to the action sequence" do
        @vm.env.actions.expects(:run).with(:start, :foo => :bar).once
        @vm.start(:foo => :bar)
      end

      should "raise an exception if the VM is not accessible" do
        @mock_vm.stubs(:accessible?).returns(false)

        assert_raises(Vagrant::Errors::VMInaccessible) {
          @vm.start
        }
      end
    end
  end
end
