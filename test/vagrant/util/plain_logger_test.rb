require "test_helper"

class PlainLoggerUtilTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Util::PlainLogger
    @instance = @klass.new(nil)
  end

  should "inherit from the standard logger" do
    assert @instance.is_a?(::Logger)
  end

  should "just add a newline to the message" do
    msg = "foo bar baz"
    assert_equal "#{msg}\n", @instance.format_message("1", "2", "3", msg)
  end
end
