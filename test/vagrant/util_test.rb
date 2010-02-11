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
    setup do
      @config = Vagrant::Config::Top.new
      Vagrant::Config.stubs(:config).returns(@config)
    end

    should "return a logger to nil if config is not loaded" do
      @config.expects(:loaded?).returns(false)
      Vagrant::Logger.expects(:new).with(nil).once.returns("foo")
      assert_equal "foo", RegUtil.logger
    end

    should "return a logger using the configured output" do
      @config.stubs(:loaded?).returns(true)
      @config.vagrant.log_output = "foo"
      Vagrant::Logger.expects(:new).once.with("foo").returns("bar")
      assert_equal "bar", RegUtil.logger
      assert_equal "bar", RegUtil.logger
    end
  end
end
