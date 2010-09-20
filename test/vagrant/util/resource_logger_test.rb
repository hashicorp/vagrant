require "test_helper"

class ResourceLoggerUtilTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Util::ResourceLogger
  end

  context "singleton logger" do
    setup do
      @klass.reset_singleton_logger!

      @result = mock("result")
    end

    should "return a nil plain logger if the environment is not loaded" do
      env = vagrant_env
      env.stubs(:loaded?).returns(false)

      Vagrant::Util::PlainLogger.expects(:new).with(nil).returns(@result)
      assert_equal @result, @klass.singleton_logger(env)
    end

    should "return a logger with the output file set if environment is ready" do
      env = vagrant_env

      Vagrant::Util::PlainLogger.expects(:new).returns(@result).with() do |path|
        assert path.to_s =~ /logs/
        true
      end

      assert_equal @result, @klass.singleton_logger(env)
    end

    should "only load the logger once" do
      env = vagrant_env

      Vagrant::Util::PlainLogger.expects(:new).with(anything).returns(@result)
      assert_equal @result, @klass.singleton_logger(env)
      assert_equal @result, @klass.singleton_logger(env)
      assert_equal @result, @klass.singleton_logger(env)
    end
  end

  context "initialization" do
    should "setup the logger and attributes" do
      env = vagrant_env
      resource = mock("resource")
      result = mock("result")

      @klass.expects(:singleton_logger).with(env).returns(result)
      instance = @klass.new(resource, env)
      assert_equal resource, instance.resource
      assert_equal env, instance.env
      assert_equal result, instance.logger
    end
  end

  context "with an instance" do
    setup do
      @resource = "foo"
      @env = vagrant_env
      @logger = mock("logger")

      @klass.stubs(:singleton_logger).returns(@logger)
      @instance = @klass.new(@resource, @env)
    end

    context "logging methods" do
      [:debug, :info, :error, :fatal].each do |method|
        should "log with the proper format on #{method}" do
          message = "bar"
          @logger.expects(method).with("[#{@resource}] #{message}").once
          @instance.send(method, message)
        end
      end
    end
  end
end
