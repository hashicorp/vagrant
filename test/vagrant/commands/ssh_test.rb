require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsSSHTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::SSH

    @env = mock_environment
    @env.stubs(:require_persisted_vm)

    @persisted_vm = mock_vm(@env)
    @persisted_vm.stubs(:execute!)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @persisted_vm.ssh.stubs(:connect)
    end

    should "require a persisted VM" do
      @env.expects(:require_persisted_vm).once
      @instance.execute
    end

    should "connect to SSH" do
      @persisted_vm.ssh.expects(:connect).once
      @instance.execute
    end
  end
end
