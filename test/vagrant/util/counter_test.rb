require "test_helper"

class CounterUtilTest < Test::Unit::TestCase
  setup do
    @klass = Class.new do
      extend Vagrant::Util::Counter
    end
  end

  context "basic counter" do
    should "get and update the counter" do
      assert_equal 1, @klass.get_and_update_counter
      assert_equal 2, @klass.get_and_update_counter
    end
  end

  context "multiple classes with a counter" do
    setup do
      @klass2 = Class.new do
        extend Vagrant::Util::Counter
      end
    end

    should "not affect other classes" do
      assert_equal 1, @klass.get_and_update_counter
      assert_equal 1, @klass2.get_and_update_counter
    end
  end
end
