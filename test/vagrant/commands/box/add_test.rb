require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class CommandsBoxAddTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Box::Add

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @name = "foo"
      @path = "bar"
    end

    should "execute the add action with the name and path" do
      Vagrant::Box.expects(:add).with(@env, @name, @path).once
      @instance.execute([@name, @path])
    end

    should "show help if not enough arguments" do
      Vagrant::Box.expects(:add).never
      @instance.expects(:show_help).once
      @instance.execute([])
    end
  end
end
