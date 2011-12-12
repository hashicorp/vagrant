require "test_helper"

class WindowsSystemTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Systems::Windows
    @ssh = mock("ssh")
    @mock_env = vagrant_env
    @vm = mock("vm")
    @vm.stubs(:env).returns(@mock_env)
    @instance = @klass.new(@vm)
  end

  context "commands" do
    setup do
      @ssh_session = mock("ssh_session")
      @ssh.stubs(:execute).yields(@ssh_session)
      @vm.stubs(:ssh).returns(@ssh)

      @real_vm = mock("real_vm")
      @real_vm.stubs(:state).returns(:powered_off)
      @vm.stubs(:vm).returns(@real_vm)
    end

    should "execute halt via SSH" do
      @ssh_session.expects(:exec!).with('shutdown.exe /l /t:1 "Vagrant Shutdown" /y /c').once
      @instance.halt
    end

    should "rename the hostname via SSH" do
      @ssh_session.expects(:exec!).with("C:/Windows/System32/wbem/WMIC.exe computersystem where name=\"%COMPUTERNAME%\" call rename name=\"comp_name\"")
      @instance.change_host_name("comp_name")
    end
  end
end
