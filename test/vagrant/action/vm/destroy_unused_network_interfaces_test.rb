require "test_helper"

class DestroyUnusedNetworkInterfacesVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::DestroyUnusedNetworkInterfaces
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    setup do
      @network_adapters = []
      @internal_vm.stubs(:network_adapters).returns(@network_adapters)
    end

    def stub_interface(length=5)
      interface = mock("interface")
      adapter = mock("adapter")
      adapter.stubs(:host_interface_object).returns(interface)
      interface.stubs(:attached_vms).returns(Array.new(length))

      @network_adapters << adapter
      interface
    end

    should "destroy only the unused network interfaces" do
      stub_interface(5)
      stub_interface(7)
      results = [stub_interface(1), stub_interface(1)]

      results.each do |result|
        result.expects(:destroy).once
      end

      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end
  end
end
