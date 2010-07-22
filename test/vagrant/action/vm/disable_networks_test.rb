require "test_helper"

class DisableNetworksVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::DisableNetworks
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env.env.stubs(:vm).returns(@vm)

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
    @internal_vm.stubs(:network_adapters).returns([])

    @instance = @klass.new(@app, @env)
  end

  def mock_adapter(type)
    adapter = mock("adapter")
    adapter.stubs(:attachment_type).returns(type)

    if type == :host_only
      adapter.expects(:enabled=).with(false)
      adapter.expects(:save)
    end

    @internal_vm.network_adapters << adapter
  end

  should "remove all network adapters and continue chain" do
    mock_adapter(:bridged)
    mock_adapter(:host_only)
    mock_adapter(:host_only)

    @app.expects(:call).with(@env).once

    @instance.call(@env)
  end
end
