require "test_helper"

class ClearForwardedPortsVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ClearForwardedPorts
    @app, @env = action_env

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @env["vm"] = @vm
    @env["vm.modify"] = mock("proc")

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    def mock_fp
      fp = mock("fp")
      fp.expects(:destroy).once
      fp
    end

    def mock_adapter
      na = mock("adapter")
      engine = mock("engine")
      engine.stubs(:forwarded_ports).returns([mock_fp])
      na.stubs(:nat_driver).returns(engine)
      na
    end

    setup do
      VirtualBox.stubs(:version).returns("3.2.8")
      @adapters = []
      @internal_vm = mock("internal_vm")
      @internal_vm.stubs(:network_adapters).returns(@adapters)
      @vm.stubs(:vm).returns(@internal_vm)
    end

    should "call the proper methods and continue chain" do
      @adapters << mock_adapter
      @adapters << mock_adapter

      @env["vm.modify"].expects(:call).with() do |proc|
        proc.call(@internal_vm)
        true
      end

      @app.expects(:call).with(@env)
      @instance.call(@env)
    end
  end
end
