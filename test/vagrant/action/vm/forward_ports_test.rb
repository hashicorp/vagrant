require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ForwardPortsVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ForwardPorts
    @app, @env = mock_action_data

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @env["vm"] = @vm
  end

  context "initializing" do
    should "call proper methods" do
      @klass.any_instance.expects(:external_collision_check)
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
      @used_ports << "80"
      @klass.new(@app, @env)
      assert !@env.error?
    end

    should "handle collision if it happens" do
      @used_ports << "2222"
      @klass.any_instance.expects(:handle_collision).with("ssh", anything, anything).once
      @klass.new(@app, @env)
      assert !@env.error?
    end
  end

  context "with instance" do
    setup do
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
        @instance.handle_collision(@name, @options, @used_ports)
        assert @env.error?
        assert_equal :vm_port_collision, @env.error.first
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
        @instance.handle_collision(@name, @options, @used_ports)
        assert @env.error?
        assert_equal :vm_port_auto_empty, @env.error.first
      end
    end

    context "calling" do
      should "clear all previous ports and forward new ports" do
        exec_seq = sequence("exec_seq")
        @instance.expects(:clear).once.in_sequence(exec_seq)
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
        @internal_vm.expects(:save).once
        @vm.expects(:reload!).once
        @instance.forward_ports
      end

      should "not port forward for non NAT interfaces" do
        forwarded_ports = mock("forwarded_ports")
        network_adapter = mock("network_adapter")

        @internal_vm.expects(:network_adapters).returns([network_adapter])
        network_adapter.expects(:attachment_type).returns(:host_only)
        @internal_vm.expects(:save).once
        @vm.expects(:reload!).once
        @instance.forward_ports
      end
    end

    context "clearing forwarded ports" do
      setup do
        @instance.stubs(:used_ports).returns([:a])
        @instance.stubs(:clear_ports)
      end

      should "call destroy on all forwarded ports" do
        @instance.expects(:clear_ports).once
        @vm.expects(:reload!)
        @instance.clear
      end

      should "do nothing if there are no forwarded ports" do
        @instance.stubs(:used_ports).returns([])
        @vm.expects(:reload!).never
        @instance.clear
      end
    end

    context "getting list of used ports" do
      setup do
        @vms = []
        VirtualBox::VM.stubs(:all).returns(@vms)
        VirtualBox.stubs(:version).returns("3.1.0")
        @vm.stubs(:uuid).returns(:bar)
      end

      def mock_vm(options={})
        options = {
          :running? => true,
          :uuid => :foo
        }.merge(options)

        vm = mock("vm")
        options.each do |k,v|
          vm.stubs(k).returns(v)
        end

        vm
      end

      def mock_fp(hostport)
        fp = mock("fp")
        fp.stubs(:hostport).returns(hostport.to_s)
        fp
      end

      should "ignore VMs which aren't running" do
        @vms << mock_vm(:running? => false)
        @vms[0].expects(:forwarded_ports).never
        @instance.used_ports
      end

      should "ignore VMs of the same uuid" do
        @vms << mock_vm(:uuid => @vm.uuid)
        @vms[0].expects(:forwarded_ports).never
        @instance.used_ports
      end

      should "return the forwarded ports for VB 3.2.x" do
        VirtualBox.stubs(:version).returns("3.2.4")
        fps = [mock_fp(2222), mock_fp(80)]
        na = mock("na")
        ne = mock("ne")
        na.stubs(:nat_driver).returns(ne)
        ne.stubs(:forwarded_ports).returns(fps)
        @vms << mock_vm(:network_adapters => [na])
        assert_equal %W[2222 80], @instance.used_ports
      end
    end

    context "clearing ports" do
      def mock_fp
        fp = mock("fp")
        fp.expects(:destroy).once
        fp
      end

      setup do
        VirtualBox.stubs(:version).returns("3.2.8")
        @adapters = []
        @internal_vm = mock("internal_vm")
        @internal_vm.stubs(:network_adapters).returns(@adapters)
        @vm.stubs(:vm).returns(@internal_vm)
      end

      def mock_adapter
        na = mock("adapter")
        engine = mock("engine")
        engine.stubs(:forwarded_ports).returns([mock_fp])
        na.stubs(:nat_driver).returns(engine)
        na
      end

      should "destroy each forwarded port" do
        @adapters << mock_adapter
        @adapters << mock_adapter
        @instance.clear_ports
      end
    end

    context "forwarding ports implementation" do
      setup do
        VirtualBox.stubs(:version).returns("3.2.8")

        @internal_vm = mock("internal_vm")
        @vm.stubs(:vm).returns(@internal_vm)
      end

      should "forward ports" do
        name, opts = @env.env.config.vm.forwarded_ports.first

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

        @instance.forward_port(name, opts)
      end
    end
  end
end
