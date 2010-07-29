require "test_helper"

class CommandsBoxRepackageTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Box::Repackage

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
      @instance.execute(["--include", "x,y,z"])
    end

    should "error and exit if the box doesn't exist" do
      Vagrant::Box.expects(:find).returns(nil)
      @instance.expects(:error_and_exit).with(:box_repackage_doesnt_exist).once
      @instance.execute([@name])
    end

    should "call repackage on the box if it exists" do
      @box = mock("box")
      Vagrant::Box.expects(:find).with(@env, @name).returns(@box)
      @box.expects(:repackage).once
      @instance.execute([@name])
    end

    should "pass given options into repackage" do
      @box = mock("box")
      Vagrant::Box.expects(:find).with(@env, @name).returns(@box)
      @box.expects(:repackage).once.with() do |opts|
        assert opts.is_a?(Hash)
        assert_equal "filename.box", opts["package.output"]
        true
      end
      @instance.execute([@name, "--output", "filename.box"])
    end
  end
end
