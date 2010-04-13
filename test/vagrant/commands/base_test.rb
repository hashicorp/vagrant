require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsBastTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Base
  end

  context "initializing" do
    should "setup the env attribute" do
      env = mock("env")
      instance = @klass.new(env)
      assert_equal env, instance.env
    end
  end

  context "class methods" do
    setup do
      @env = mock_environment
      @klass.subcommands.clear
    end

    context "registering commands" do
      should "register commands" do
        klass = mock("klass")
        @klass.subcommand("init", klass)
        assert_equal klass, @klass.subcommands["init"]
      end
    end

    context "dispatching to subcommands" do
      setup do
        @command_klass = mock("klass")
        @name = "init"
        @klass.subcommand(@name, @command_klass)

        @args = [1,2,3]
      end

      should "call dispatch on child if subcommand is found" do
        @command_klass.expects(:dispatch).with(@env, *@args)
        @klass.dispatch(@env, @name, *@args)
      end

      should "instantiate and execute when no subcommand is found" do
        instance = mock("instance")
        @klass.expects(:new).with(@env).returns(instance)
        instance.expects(:execute).with(@args)
        @klass.dispatch(@env, *@args)
      end
    end

    context "descriptions" do
      should "be able to set description" do
        description = "The lazy fox yada yada"
        @klass.description(description)
        assert_equal description, @klass.description
      end
    end
  end

  context "instance methods" do
    setup do
      @env = mock_environment
      @instance = @klass.new(@env)
    end

    context "executing" do
      should "just print the help" do
        @klass.expects(:puts_help)
        @instance.execute([])
      end
    end

    context "parsing options" do
      setup do
        @args = []
      end

      should "return the options hash" do
        value = mock("foo")
        result = @instance.parse_options(@args) do |opts, options|
          options[:foo] = value
        end

        assert_equal value, result[:foo]
      end

      should "parse with the given args" do
        parser = mock("parser")

        OptionParser.stubs(:new).returns(parser)
        parser.expects(:parse!).with(@args)
        @instance.parse_options(@args) do; end
      end

      should "show help if an invalid options error is raised" do
        parser = mock("parser")

        OptionParser.stubs(:new).returns(parser)
        parser.expects(:parse!).raises(OptionParser::InvalidOption)
        @instance.expects(:show_help).once

        @instance.parse_options(@args) do; end
      end
    end
  end
end
