require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ActionBuilderTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Builder
  end

  context "initializing" do
    should "setup empty middleware stack" do
      builder = @klass.new
      assert builder.stack.empty?
    end

    should "take block to setup stack" do
      builder = @klass.new do
        use Hash
        use lambda { |i| i }
      end

      assert !builder.stack.empty?
      assert_equal 2, builder.stack.length
    end
  end

  context "with an instance" do
    setup do
      @instance = @klass.new
    end

    context "adding to the stack" do
      should "add to the end" do
        @instance.use 1
        @instance.use 2
        assert_equal [2, [], nil], @instance.stack.last
      end
    end

    context "converting to an app" do

    end
  end
end
