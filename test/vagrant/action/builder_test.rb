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

      should "merge in other builder's stack" do
        other = @klass.new do
          use 2
          use 3
        end

        @instance.use 1
        @instance.use other
        assert_equal 3, @instance.stack.length
      end
    end

    context "converting to an app" do
      should "initialize each middleware with app and env" do
        # TODO: better testing of this method... somehow

        result = mock("result")
        env = {:a => :b}
        middleware = mock("middleware")
        middleware.expects(:new).with(anything, env).returns(result)
        @instance.use middleware
        assert_equal result, @instance.to_app(env)
      end
    end

    context "calling" do
      def mock_middleware
        middleware = Class.new do
          def initialize(app, env)
            @app = app
          end

          def call(env)
            @app.call(env)
          end
        end
      end

      should "convert to an app then call with the env" do
        mw = mock_middleware
        mw.any_instance.expects(:call).with() do |env|
          assert env.has_key?(:key)
          true
        end

        @instance.use(mw)
        @instance.call(:key => :value)
      end
    end
  end
end
