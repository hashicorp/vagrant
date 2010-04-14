require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsStatusTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Status

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    # TODO
  end
end
