require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsSSHTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::SSH

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @env.ssh.stubs(:connect)
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      @instance.execute
    end

    should "connect to SSH" do
      @env.ssh.expects(:connect).once
      @instance.execute
    end
  end
end
