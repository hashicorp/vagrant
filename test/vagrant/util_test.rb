require "test_helper"

class UtilTest < Test::Unit::TestCase
  class UtilIncludeTest
    include Vagrant::Util
  end

  setup do
    @klass = UtilIncludeTest
  end

  context "with a class" do
    should "have the util methods" do
      assert @klass.respond_to?(:error_and_exit)
    end
  end

  context "with an instance" do
    setup do
      @instance = @klass.new
    end

    should "have the util methods" do
      assert @instance.respond_to?(:error_and_exit)
    end
  end
end
