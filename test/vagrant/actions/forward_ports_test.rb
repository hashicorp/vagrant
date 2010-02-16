require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ForwardPortsActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::ForwardPorts)
    mock_config
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
      @action.forward_ports
    end
  end

  context "clearing forwarded ports" do
    should "call destroy on all forwarded ports" do
      forwarded_ports = []
      5.times do |i|
        port = mock("port#{i}")
        port.expects(:destroy).with(true).once
        forwarded_ports << port
      end

      @vm.expects(:forwarded_ports).returns(forwarded_ports)
      @action.clear
    end
  end
end
