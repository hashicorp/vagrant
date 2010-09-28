require "test_helper"

class ShUtilTest < Test::Unit::TestCase
  setup do
    @klass = Class.new do
      extend Vagrant::Util::Sh
    end
  end

  should "execute and return the output" do
    out, _ = @klass.sh("echo 'hello'")
    assert_equal "hello\n", out
  end

  should "populate the exit status variable" do
    _, status = @klass.sh("echo")
    assert status.success?

    _, status = @klass.sh("sdklfjslkfj")
    assert !status.success?
  end
end
