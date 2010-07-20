require "test_helper"

class MatchMACAddressVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::MatchMACAddress
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  should "match the mac addresses" do
    nic = mock("nic")
    nic.expects(:mac_address=).once

    update_seq = sequence("update_seq")
    @internal_vm.expects(:network_adapters).returns([nic]).once.in_sequence(update_seq)
    @internal_vm.expects(:save).once.in_sequence(update_seq)
    @app.expects(:call).with(@env).once.in_sequence(update_seq)

    @instance.call(@env)
  end
end
