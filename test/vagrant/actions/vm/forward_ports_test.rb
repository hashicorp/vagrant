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
      @forwarded_port = mock("forwarded_port")
      @forwarded_port.stubs(:hostport)
      @forwarded_ports = [@forwarded_port]

      @vm = mock("vm")
      @vm.stubs(:forwarded_ports).returns(@forwarded_ports)
      @vm.stubs(:running?).returns(true)
      @vm.stubs(:uuid).returns("foo")
      @runner.stubs(:uuid).returns("bar")
      vms = [@vm]
      VirtualBox::VM.stubs(:all).returns(vms)

      @env = mock_environment do |config|
        config.vm.forwarded_ports.clear
        config.vm.forward_port("ssh", 22, 2222)
      end

      @runner.stubs(:env).returns(@env)

      # So no exceptions are raised
      @action.stubs(:handle_collision)
    end

    should "ignore vms which aren't running" do
      @vm.expects(:running?).returns(false)
      @vm.expects(:forwarded_ports).never
      @action.external_collision_check
    end

    should "ignore vms which are equivalent to ours" do
      @runner.expects(:uuid).returns(@vm.uuid)
      @vm.expects(:forwarded_ports).never
      @action.external_collision_check
    end

    should "not raise any errors if no forwarded ports collide" do
      @forwarded_port.expects(:hostport).returns(80)
      assert_nothing_raised { @action.external_collision_check }
    end

    should "handle the collision if it happens" do
      @forwarded_port.expects(:hostport).returns(2222)
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

      @vm.expects(:network_adapters).returns([network_adapter])
      network_adapter.expects(:attachment_type).returns(:nat)

      @runner.env.config.vm.forwarded_ports.each do |name, opts|
        forwarded_ports.expects(:<<).with do |port|
          assert_equal name, port.name
          assert_equal opts[:hostport], port.hostport
          assert_equal opts[:guestport], port.guestport
          assert_equal opts[:adapter], port.instance
          true
        end
      end

      @vm.expects(:forwarded_ports).returns(forwarded_ports)
      @vm.expects(:save).once
      @action.forward_ports
    end
  end

  context "Not forwarding ports" do
    should "No port forwarding for non NAT interfaces" do
      forwarded_ports = mock("forwarded_ports")
      network_adapter = mock("network_adapter")

      @vm.expects(:network_adapters).returns([network_adapter])
      network_adapter.expects(:attachment_type).returns(:host_only)
      @vm.expects(:save).once
      @action.forward_ports
    end
  end

  context "clearing forwarded ports" do
    should "call destroy on all forwarded ports" do
      forwarded_ports = []
      5.times do |i|
        port = mock("port#{i}")
        port.expects(:destroy).once
        forwarded_ports << port
      end

      @vm.stubs(:forwarded_ports).returns(forwarded_ports)
      @runner.expects(:reload!)
      @action.clear
    end

    should "do nothing if there are no forwarded ports" do
      @vm.stubs(:forwarded_ports).returns([])
      @runner.expects(:reload!).never
      @action.clear
    end
  end
end
