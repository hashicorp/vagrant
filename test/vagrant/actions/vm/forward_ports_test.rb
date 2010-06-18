require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ForwardPortsActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::ForwardPorts)
  end

  context "preparing" do
    should "call proper sequence" do
      prep_seq = sequence("prepare")
      @action.expects(:external_collision_check).in_sequence(prep_seq)
      @action.prepare
    end
  end

  context "checking for colliding external ports" do
    setup do
      @env = mock_environment do |config|
        config.vm.forwarded_ports.clear
        config.vm.forward_port("ssh", 22, 2222)
      end

      @runner.stubs(:env).returns(@env)

      @used_ports = []
      @action.stubs(:used_ports).returns(@used_ports)

      # So no exceptions are raised
      @action.stubs(:handle_collision)
    end

    should "not raise any errors if no forwarded ports collide" do
      @used_ports << "80"
      assert_nothing_raised { @action.external_collision_check }
    end

    should "handle the collision if it happens" do
      @used_ports << "2222"
      @action.expects(:handle_collision).with("ssh", anything, anything).once
      @action.external_collision_check
    end
  end

  context "handling collisions" do
    setup do
      @name = :foo
      @options = {
        :hostport => 0,
        :auto => true
      }
      @used_ports = [1,2,3]

      @runner.env.config.vm.auto_port_range = (1..5)
    end

    should "raise an exception if auto forwarding is disabled" do
      @options[:auto] = false

      assert_raises(Vagrant::Actions::ActionException) {
        @action.handle_collision(@name, @options, @used_ports)
      }
    end

    should "set the host port to the first available port" do
      assert_equal 0, @options[:hostport]
      @action.handle_collision(@name, @options, @used_ports)
      assert_equal 4, @options[:hostport]
    end

    should "add the newly used port to the list of used ports" do
      assert !@used_ports.include?(4)
      @action.handle_collision(@name, @options, @used_ports)
      assert @used_ports.include?(4)
    end

    should "not use a host port which is being forwarded later" do
      @runner.env.config.vm.forward_port("http", 80, 4)

      assert_equal 0, @options[:hostport]
      @action.handle_collision(@name, @options, @used_ports)
      assert_equal 5, @options[:hostport]
    end

    should "raise an exception if there are no auto ports available" do
      @runner.env.config.vm.auto_port_range = (1..3)
      assert_raises(Vagrant::Actions::ActionException) {
        @action.handle_collision(@name, @options, @used_ports)
      }
    end
  end

  context "execution" do
    should "clear all previous ports and forward new ports" do
      exec_seq = sequence("exec_seq")
      @action.expects(:clear).once.in_sequence(exec_seq)
      @action.expects(:forward_ports).once.in_sequence(exec_seq)
      @action.execute!
    end
  end

  context "forwarding ports" do
    should "create a port forwarding for the VM" do
      forwarded_ports = mock("forwarded_ports")
      network_adapter = mock("network_adapter")

      @vm.stubs(:network_adapters).returns([network_adapter])
      network_adapter.expects(:attachment_type).returns(:nat)

      @action.expects(:forward_port).once
      @vm.expects(:save).once
      @runner.expects(:reload!).once
      @action.forward_ports
    end

    should "No port forwarding for non NAT interfaces" do
      forwarded_ports = mock("forwarded_ports")
      network_adapter = mock("network_adapter")

      @vm.expects(:network_adapters).returns([network_adapter])
      network_adapter.expects(:attachment_type).returns(:host_only)
      @vm.expects(:save).once
      @runner.expects(:reload!).once
      @action.forward_ports
    end
  end

  context "clearing forwarded ports" do
    setup do
      @action.stubs(:used_ports).returns([:a])
      @action.stubs(:clear_ports)
    end

    should "call destroy on all forwarded ports" do
      @action.expects(:clear_ports).once
      @runner.expects(:reload!)
      @action.clear
    end

    should "do nothing if there are no forwarded ports" do
      @action.stubs(:used_ports).returns([])
      @runner.expects(:reload!).never
      @action.clear
    end
  end

  context "getting list of used ports" do
    setup do
      @vms = []
      VirtualBox::VM.stubs(:all).returns(@vms)
      VirtualBox.stubs(:version).returns("3.1.0")
      @runner.stubs(:uuid).returns(:bar)
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
      @action.used_ports
    end

    should "ignore VMs of the same uuid" do
      @vms << mock_vm(:uuid => @runner.uuid)
      @vms[0].expects(:forwarded_ports).never
      @action.used_ports
    end

    should "return the forwarded ports for VB 3.2.x" do
      VirtualBox.stubs(:version).returns("3.2.4")
      fps = [mock_fp(2222), mock_fp(80)]
      na = mock("na")
      ne = mock("ne")
      na.stubs(:nat_driver).returns(ne)
      ne.stubs(:forwarded_ports).returns(fps)
      @vms << mock_vm(:network_adapters => [na])
      assert_equal %W[2222 80], @action.used_ports
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
      @vm.stubs(:network_adapters).returns(@adapters)
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
      @action.clear_ports
    end
  end

  context "forwarding ports implementation" do
    setup do
      VirtualBox.stubs(:version).returns("3.2.8")
    end

    should "forward ports" do
      name, opts = @runner.env.config.vm.forwarded_ports.first

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
      @vm.stubs(:network_adapters).returns(adapters)

      @action.forward_port(name, opts)
    end
  end
end
