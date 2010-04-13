require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsBaseTest < Test::Unit::TestCase
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
      should "show version if flag is set" do
        @instance.expects(:puts_version).once
        @instance.expects(:puts_help).never
        @instance.execute(["--version"])
      end

      should "just print the help by default" do
        @instance.expects(:puts_version).never
        @klass.expects(:puts_help)
        @instance.execute([])
      end
    end

    context "getting the option parser" do
      should "create it with the options spec if it hasn't been created yet" do
        opts = mock("opts")
        result = mock("result")
        OptionParser.expects(:new).yields(opts).returns(result)
        @instance.expects(:options_spec).with(opts)

        assert_equal result, @instance.option_parser(true)
      end

      should "not create it once its been created" do
        result = mock("result")
        OptionParser.expects(:new).once.returns(result)

        assert_equal result, @instance.option_parser(true)
        assert_equal result, @instance.option_parser
        assert_equal result, @instance.option_parser
      end
    end

    context "parsing options" do
      setup do
        @args = []

        @options = mock("options")
        @option_parser = mock("option_parser")

        @instance.stubs(:option_parser).returns(@option_parser)
        @instance.stubs(:options).returns(@options)
      end

      should "parse the options with the args" do
        @option_parser.expects(:parse!).with(@args).once
        assert_equal @options, @instance.parse_options(@args)
      end
    end
  end
end
