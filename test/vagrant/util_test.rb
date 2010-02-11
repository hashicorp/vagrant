require File.join(File.dirname(__FILE__), '..', 'test_helper')

class UtilTest < Test::Unit::TestCase
  class RegUtil
    extend Vagrant::Util
  end

  context "erroring" do
    # TODO: Any way to stub Kernel.exit? Can't test nicely
    # otherwise
  end

  context "logger" do
    class OtherUtil
      extend Vagrant::Util
    end

    setup do
      @config = Vagrant::Config::Top.new
      @config.stubs(:loaded?).returns(true)
      @config.vagrant.log_output = STDOUT
      Vagrant::Config.stubs(:config).returns(@config)
      Vagrant::Logger.reset_logger!
    end

    teardown do
      Vagrant::Logger.reset_logger!
    end

    should "return a logger to nil if config is not loaded" do
      @config.expects(:loaded?).returns(false)
      logger = RegUtil.logger
      assert_nil logger.instance_variable_get(:@logdev)
    end

    should "return a logger using the configured output" do
      logger = RegUtil.logger
      logdev = logger.instance_variable_get(:@logdev)
      assert logger
      assert !logdev.nil?
      assert_equal STDOUT, logdev.dev
    end

    should "only instantiate a logger once" do
      Vagrant::Logger.expects(:new).once.returns("GOOD")
      RegUtil.logger
      RegUtil.logger
    end

    should "be able to reset the logger" do
      Vagrant::Logger.expects(:new).twice
      RegUtil.logger
      Vagrant::Logger.reset_logger!
      RegUtil.logger
    end

    should "return the same logger across classes" do
      logger = RegUtil.logger
      other = OtherUtil.logger

      assert logger.equal?(other)
    end
  end
end
