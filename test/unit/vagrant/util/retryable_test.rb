require "test_helper"

class RetryableUtilTest < Test::Unit::TestCase
  setup do
    @klass = Class.new do
      extend Vagrant::Util::Retryable
    end
  end

  should "retry specified number of times if exception is raised" do
    proc = mock("proc")
    proc.expects(:call).twice

    assert_raises(RuntimeError) {
      @klass.retryable(:tries => 2, :on => RuntimeError) do
        proc.call
        raise "An error"
      end
    }
  end

  should "only retry on specified exception" do
    proc = mock("proc")
    proc.expects(:call).once

    assert_raises(StandardError) {
      @klass.retryable(:tries => 5, :on => RuntimeError) do
        proc.call
        raise StandardError.new
      end
    }
  end

  should "retry on multiple exceptions given" do
    proc = mock("proc")
    proc.expects(:call).twice

    assert_raises(StandardError) {
      @klass.retryable(:tries => 2, :on => [StandardError, RuntimeError]) do
        proc.call
        raise StandardError
      end
    }
  end

  should "return the value of the block" do
    result = @klass.retryable { 7 }
    assert_equal 7, result
  end
end
