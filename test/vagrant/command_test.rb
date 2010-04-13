require File.join(File.dirname(__FILE__), '..', 'test_helper')

class CommandTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Command
  end

  context "initializing" do
    setup do
      @env = mock("environment")
    end

    should "set the env attribute" do
      @instance = @klass.new(@env)
      assert_equal @env, @instance.env
    end
  end

  context "class methods" do
    context "executing" do
      should "load the environment then send the command on commands" do
        env = mock("env")
        commands = mock("commands")
        env.stubs(:commands).returns(commands)
        Vagrant::Environment.expects(:load!).returns(env)
        commands.expects(:subcommand).with(1,2,3).once

        @klass.execute(1,2,3)
      end
    end
  end

  context "with an instance" do
    setup do
      @env = mock_environment
      @instance = @klass.new(@env)
    end

    context "subcommands" do
      setup do
        @raw_name = :bar
        @name = :foo
        @instance.stubs(:camelize).with(@raw_name).returns(@name)
      end

      should "send the env, name, and args to the base class" do
        args = [1,2,3]
        Vagrant::Commands::Base.expects(:dispatch).with(@env, @name, *args)
        @instance.subcommand(@name, *args)
      end
    end
  end
end
