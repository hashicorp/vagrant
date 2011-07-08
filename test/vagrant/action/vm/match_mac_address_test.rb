require "test_helper"

class MatchMACAddressVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::MatchMACAddress
    @app, @env = action_env

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
    @app.expects(:call).with(@env).once.in_sequence(update_seq)

    @env["vm.modify"].expects(:call).with() do |proc|
      proc.call(@internal_vm)
      true
    end

    @instance.call(@env)
  end

  should "raise an exception if no base MAC address is specified" do
    @env.env.config.vm.base_mac = nil

    assert_raises(Vagrant::Errors::VMBaseMacNotSpecified) {
      @instance.call(@env)
    }
  end
end
