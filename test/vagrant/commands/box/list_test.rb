require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class CommandsBoxListTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Box::List

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @boxes = ["foo", "bar"]

      Vagrant::Box.stubs(:all).returns(@boxes)
      @instance.stubs(:wrap_output)
    end

    should "call all on box and sort the results" do
      @all = mock("all")
      @all.expects(:sort).returns(@boxes)
      Vagrant::Box.expects(:all).with(@env).returns(@all)
      @instance.execute
    end
  end
end
