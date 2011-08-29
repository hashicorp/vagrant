require "test_helper"

class DestroyUnusedNetworkInterfacesVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::DestroyUnusedNetworkInterfaces
    @app, @env = action_env

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    setup do
      @interfaces = []
      global = mock("global")
      host = mock("host")
      VirtualBox::Global.stubs(:global).returns(global)
      global.stubs(:host).returns(host)
      host.stubs(:network_interfaces).returns(@interfaces)
    end

    def stub_interface(length=5, type=:host_only)
      interface = mock("interface")
      interface.stubs(:interface_type).returns(type)
      interface.stubs(:attached_vms).returns(Array.new(length))

      @interfaces << interface
      interface
    end

    should "destroy only the unused network interfaces" do
      stub_interface(5)
      stub_interface(7)
      results = [stub_interface(0), stub_interface(0)]

      results.each do |result|
        result.expects(:destroy).once
      end

      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end
  end
end
