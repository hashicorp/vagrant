require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ForwardPortsActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::ForwardPorts)
    mock_config
  end

  should "create a port forwarding for the VM" do
    forwarded_ports = mock("forwarded_ports")

    Vagrant.config.vm.forwarded_ports.each do |name, opts|
      forwarded_ports.expects(:<<).with do |port|
        assert_equal name, port.name
        assert_equal opts[:hostport], port.hostport
        assert_equal opts[:guestport], port.guestport
        true
      end
    end

    @vm.expects(:forwarded_ports).returns(forwarded_ports)
    @vm.expects(:save).with(true).once
    @action.execute!
  end
end
