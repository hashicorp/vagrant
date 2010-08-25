require "test_helper"

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
      should "return self" do
        assert @instance.equal?(@instance.use(1))
      end

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

      should "prepend a set environment task for merging middlewares if given" do
        other = @klass.new do
          use 1
        end

        @instance.use 0
        @instance.use(other, :foo => :bar)
        assert_equal 3, @instance.stack.length
        assert_equal Vagrant::Action::Env::Set, @instance.stack[1].first
      end
    end

    context "flatten" do
      should "return the flattened format of the builder" do
        env = Vagrant::Action::Environment.new(nil)
        env.expects(:foo).once

        func = lambda { |x| x.foo }
        @instance.use func
        proc = @instance.flatten
        assert proc.respond_to?(:call)
        proc.call(env)
      end
    end

    context "inserting" do
      setup do
        @instance.use "1"
        @instance.use "2"
      end

      should "insert at the proper numeric index" do
        @instance.insert(1, "3")
        assert_equal "3", @instance.stack[1].first
      end

      should "insert next to the proper object if given" do
        @instance.insert("2", "3")
        assert_equal "3", @instance.stack[1].first
      end

      should "be able to call insert_before as well" do
        @instance.insert_before("1", "0")
        assert_equal "0", @instance.stack.first.first
      end

      should "be able to insert_after" do
        @instance.insert_after("1", "0")
        assert_equal "0", @instance.stack[1].first
      end

      should "be able to insert_after using numeric index" do
        @instance.insert_after(1, "0")
        assert_equal "0", @instance.stack[2].first
      end

      should "raise an exception if invalid index" do
        assert_raises(RuntimeError) {
          @instance.insert_after("15", "0")
        }
      end
    end

    context "swapping" do
      setup do
        @instance.use "1"
        @instance.use "2"
      end

      should "be able to swap using the object" do
        @instance.swap "1", "3"
        assert_equal "3", @instance.stack.first.first
      end

      should "be able to swap using the index" do
        @instance.swap 0, "3"
        assert_equal "3", @instance.stack.first.first
      end
    end

    context "deleting" do
      setup do
        @instance.use "1"
      end

      should "delete the proper object" do
        @instance.delete("1")
        assert @instance.stack.empty?
      end

      should "delete by index if given" do
        @instance.delete(0)
        assert @instance.stack.empty?
      end
    end

    context "getting an index of an object" do
      should "return the proper index if it exists" do
        @instance.use 1
        @instance.use 2
        @instance.use 3
        assert_equal 1, @instance.index(2)
      end
    end

    context "converting to an app" do
      teardown do
        Vagrant::Action.actions.clear
      end

      should "preprend error halt to the chain" do
        result = mock("result")
        env = {:a => :b}
        middleware = mock("middleware")
        middleware.stubs(:is_a?).with(Class).returns(true)
        middleware.expects(:new).with(anything, env).returns(result)
        @instance.use middleware
        result = @instance.to_app(env).actions.first
        assert result.kind_of?(Vagrant::Action::Env::ErrorHalt)
      end

      should "make non-classes lambdas" do
        env = Vagrant::Action::Environment.new(nil)
        env.expects(:foo).once

        func = lambda { |x| x.foo }
        @instance.use func
        @instance.to_app(env).call(env)
      end

      should "raise exception if given invalid middleware" do
        @instance.use 7
        assert_raises(RuntimeError) {
          @instance.to_app(nil)
        }
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

        env = Vagrant::Action::Environment.new(nil)
        env[:key] = :value

        @instance.use(mw)
        @instance.call(env)
      end
    end
  end
end
