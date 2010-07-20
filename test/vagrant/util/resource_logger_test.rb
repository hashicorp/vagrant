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

    should "return a nil plain logger if no environment is given" do
      Vagrant::Util::PlainLogger.expects(:new).with(nil).returns(@result)
      assert_equal @result, @klass.singleton_logger
    end

    should "return a nil plain logger if the config is not loaded" do
      env = mock_environment
      env.config.stubs(:loaded?).returns(false)

      Vagrant::Util::PlainLogger.expects(:new).with(nil).returns(@result)
      assert_equal @result, @klass.singleton_logger(env)
    end

    should "return a logger with the specified output if environment is ready" do
      output = mock("output")
      env = mock_environment
      env.config.vagrant.log_output = output

      Vagrant::Util::PlainLogger.expects(:new).with(output).returns(@result)
      assert_equal @result, @klass.singleton_logger(env)
    end

    should "only load the logger once" do
      output = mock("output")
      env = mock_environment
      env.config.vagrant.log_output = output

      Vagrant::Util::PlainLogger.expects(:new).with(output).returns(@result)
      assert_equal @result, @klass.singleton_logger(env)
      assert_equal @result, @klass.singleton_logger(env)
      assert_equal @result, @klass.singleton_logger(env)
    end
  end

  context "initialization" do
    should "setup the logger and attributes" do
      env = mock_environment
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
      @env = mock_environment
      @logger = mock("logger")

      @klass.stubs(:singleton_logger).returns(@logger)
      @instance = @klass.new(@resource, @env)
    end

    context "logging methods" do
      setup do
        @instance.stubs(:flush_progress)
        @instance.stubs(:cl_reset).returns("")
      end

      [:debug, :info, :error, :fatal].each do |method|
        should "log with the proper format on #{method}" do
          message = "bar"
          @logger.expects(method).with("[#{@resource}] #{message}").once
          @instance.send(method, message)
        end
      end
    end

    context "reporting progress" do
      setup do
        @instance.stubs(:flush_progress)
      end

      should "flush progress" do
        @instance.expects(:flush_progress).once
        @instance.report_progress(72, 100)
      end

      should "add the reporter to the progress reporters" do
        @instance.report_progress(72, 100)
        assert @klass.progress_reporters.has_key?(@instance.resource)
      end
    end

    context "clearing progress" do
      setup do
        @instance.stubs(:flush_progress)

        @klass.progress_reporters.clear
        @instance.report_progress(72, 100)
      end

      should "remove the key from the reporters" do
        assert @klass.progress_reporters.has_key?(@instance.resource)
        @instance.clear_progress
        assert !@klass.progress_reporters.has_key?(@instance.resource)
      end
    end

    context "command line reset" do
      setup do
        Mario::Platform.logger(nil)
      end

      context "on windows" do
        setup do
          Mario::Platform.forced = Mario::Platform::Windows7
        end

        should "just return \\r for the clear screen" do
          assert_equal  "\r", @instance.cl_reset
        end
      end

      context "on other platforms" do
        setup do
          Mario::Platform.forced = Mario::Platform::Linux
        end

        should "return the full clear screen" do
          assert_equal "\r\e[0K", @instance.cl_reset
        end
      end
    end
  end
end
