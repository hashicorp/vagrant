require "test_helper"

class ClearForwardedPortsVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ClearForwardedPorts
    @app, @env = mock_action_data

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @env["vm"] = @vm

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "call the proper methods and continue chain" do
      seq = sequence('seq')
      @instance.expects(:clear).in_sequence(seq)
      @app.expects(:call).with(@env).in_sequence(seq)
      @instance.call(@env)
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
end
