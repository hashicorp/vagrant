require "test_helper"

class ForwardPortsVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ForwardPorts
    @app, @env = action_env

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @env["vm"] = @vm
    @env["vm.modify"] = mock("proc")
  end

  context "initializing" do
    should "call proper methods" do
      @klass.any_instance.expects(:threshold_check)
      @klass.any_instance.expects(:external_collision_check)
      @klass.new(@app, @env)
    end
  end

  context "checking for threshold" do
    setup do
      @klass.any_instance.stubs(:external_collision_check)
      @env.env.config.vm.forwarded_ports.clear
    end

    should "issue a warning for ports less than 1024" do
      @env.env.config.vm.forward_port("foo", 22, 222)

      @env.ui.expects(:warn).once
      @klass.new(@app, @env)
    end

    should "not issue a warning for ports greater than 1024" do
      @env.env.config.vm.forward_port("foo", 22, 2222)

      @env.ui.expects(:warn).never
      @klass.new(@app, @env)
    end
  end

  context "checking for colliding external ports" do
    setup do
      @env.env.config.vm.forwarded_ports.clear
      @env.env.config.vm.forward_port("ssh", 22, 2222)

      @used_ports = []
      @klass.any_instance.stubs(:used_ports).returns(@used_ports)
      @klass.any_instance.stubs(:handle_collision)
    end

    should "not raise any errors if no forwarded ports collide" do
      @used_ports << 80
      assert_nothing_raised { @klass.new(@app, @env) }
    end

    should "handle collision if it happens" do
      @used_ports << 2222
      @klass.any_instance.expects(:handle_collision).with("ssh", anything, anything).once
      assert_nothing_raised { @klass.new(@app, @env) }
    end
  end

  context "with instance" do
    setup do
      @klass.any_instance.stubs(:threshold_check)
      @klass.any_instance.stubs(:external_collision_check)
      @instance = @klass.new(@app, @env)
    end

    context "handling collisions" do
      setup do
        @name = :foo
        @options = {
          :hostport => 0,
          :auto => true
        }
        @used_ports = [1,2,3]

        @env.env.config.vm.auto_port_range = (1..5)
      end

      should "error if auto forwarding is disabled" do
        @options[:auto] = false

        assert_raises(Vagrant::Errors::ForwardPortCollision) {
          @instance.handle_collision(@name, @options, @used_ports)
        }
      end

      should "set the host port to the first available port" do
        assert_equal 0, @options[:hostport]
        @instance.handle_collision(@name, @options, @used_ports)
        assert_equal 4, @options[:hostport]
      end

      should "add the newly used port to the list of used ports" do
        assert !@used_ports.include?(4)
        @instance.handle_collision(@name, @options, @used_ports)
        assert @used_ports.include?(4)
      end

      should "not use a host port which is being forwarded later" do
        @env.env.config.vm.forward_port("http", 80, 4)

        assert_equal 0, @options[:hostport]
        @instance.handle_collision(@name, @options, @used_ports)
        assert_equal 5, @options[:hostport]
      end

      should "raise an exception if there are no auto ports available" do
        @env.env.config.vm.auto_port_range = (1..3)

        assert_raises(Vagrant::Errors::ForwardPortAutolistEmpty) {
          @instance.handle_collision(@name, @options, @used_ports)
        }
      end
    end

    context "calling" do
      should "clear all previous ports and forward new ports" do
        exec_seq = sequence("exec_seq")

        @env["vm.modify"].expects(:call).with() do |proc|
          proc.call(@internal_vm)
          true
        end

        @instance.expects(:forward_ports).once.in_sequence(exec_seq)
        @app.expects(:call).once.with(@env).in_sequence(exec_seq)
        @instance.call(@env)
      end
    end

    context "forwarding ports" do
      setup do
        @internal_vm = mock("internal_vm")
        @vm.stubs(:vm).returns(@internal_vm)
      end

      should "create a port forwarding for the VM" do
        forwarded_ports = mock("forwarded_ports")
        network_adapter = mock("network_adapter")

        @internal_vm.stubs(:network_adapters).returns([network_adapter])
        network_adapter.expects(:attachment_type).returns(:nat)

        @instance.expects(:forward_port).once

        @instance.forward_ports(@internal_vm)
      end

      should "not port forward for non NAT interfaces" do
        forwarded_ports = mock("forwarded_ports")
        network_adapter = mock("network_adapter")

        @internal_vm.expects(:network_adapters).returns([network_adapter])
        network_adapter.expects(:attachment_type).returns(:host_only)

        @instance.forward_ports(@internal_vm)
      end
    end

    context "forwarding ports implementation" do
      setup do
        VirtualBox.stubs(:version).returns("3.2.8")

        @internal_vm = mock("internal_vm")
        @vm.stubs(:vm).returns(@internal_vm)
      end

      should "forward ports" do
        name = @env.env.config.vm.forwarded_ports.keys.first
        opts = @env.env.config.vm.forwarded_ports[name]

        adapters = []
        adapter = mock("adapter")
        engine = mock("engine")
        fps = mock("forwarded ports")
        adapter.stubs(:nat_driver).returns(engine)
        engine.stubs(:forwarded_ports).returns(fps)
        fps.expects(:<<).with do |port|
          assert_equal name, port.name
          assert_equal opts[:hostport], port.hostport
          assert_equal opts[:guestport], port.guestport
          true
        end

        adapters[opts[:adapter]] = adapter
        @internal_vm.stubs(:network_adapters).returns(adapters)

        @instance.forward_port(@internal_vm, name, opts)
      end
    end
  end
end
