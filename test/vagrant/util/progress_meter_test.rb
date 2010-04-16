require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ProgressMeterUtilTest < Test::Unit::TestCase
  class TestProgressMeter
    include Vagrant::Util::ProgressMeter
  end

  setup do
    @instance = TestProgressMeter.new

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
