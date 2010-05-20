require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class PlainLoggerUtilTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Util::PlainLogger
    @instance = @klass.new(nil)
  end

  should "inherit from the standard logger" do
    assert @instance.is_a?(::Logger)
  end

  should "not attempt to format the message in any way" do
    msg = "foo bar baz"
    assert_equal msg, @instance.format_message("1", "2", "3", msg)
  end
end
