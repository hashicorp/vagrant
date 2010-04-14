require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class CommandsBoxRemoveTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Box::Remove

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
    end

    should "show help if not enough arguments" do
      Vagrant::Box.expects(:find).never
      @instance.expects(:show_help).once
      @instance.execute([])
    end

    should "error and exit if the box doesn't exist" do
      Vagrant::Box.expects(:find).returns(nil)
      @instance.expects(:error_and_exit).with(:box_remove_doesnt_exist).once
      @instance.execute([@name])
    end

    should "call destroy on the box if it exists" do
      @box = mock("box")
      Vagrant::Box.expects(:find).with(@env, @name).returns(@box)
      @box.expects(:destroy).once
      @instance.execute([@name])
    end
  end
end
