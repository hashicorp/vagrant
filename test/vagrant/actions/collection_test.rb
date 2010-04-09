require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CollectionTest < Test::Unit::TestCase
  class MockAction; end
  class MockActionOther; end

  context "checking uniqueness" do
    setup do
      @actions = Vagrant::Actions::Collection.new([1])
    end

    should "return true if there are duplicate classes in the collection" do
      @actions << 1
      assert @actions.duplicates?
    end

    should "return false it all the classes are unique" do
      @actions << 1.0 << "foo"
      assert !@actions.duplicates?
    end

    should "raise an exception when there are duplicates" do
      @actions << 1
      assert_raise Vagrant::Actions::DuplicateActionException do
        @actions.duplicates!
      end
    end

    should "not raise an exception when there are no duplicates" do
      @actions << 1.0 << "foo"
      assert_nothing_raised do
        @actions.duplicates!
      end
    end
  end

  context "verifying dependencies" do
    setup do
      @mock_action = mock('action')
      @mock_action.stubs(:class).returns(MockAction)

      @mock_action2 = mock('action2')
      @mock_action2.stubs(:class).returns(MockActionOther)
      # see test_helper
      stub_default_action_dependecies(@mock_action)
      stub_default_action_dependecies(@mock_action2)
    end

    context "that come before an action" do
      setup do
        @mock_action.stubs(:follows).returns([MockActionOther])
      end
      should "raise an exception if they are not met" do
        assert_raise Vagrant::Actions::DependencyNotSatisfiedException do
          collection.new([@mock_action]).dependencies!
        end
      end

      should "not raise an exception if they are met" do
        assert_nothing_raised do
          collection.new([@mock_action2, @mock_action]).dependencies!
        end
      end
    end

    context "that follow an an action" do
      setup do
        @mock_action.stubs(:precedes).returns([MockActionOther])
      end

      should "raise an exception if they are not met" do
        assert_raise Vagrant::Actions::DependencyNotSatisfiedException do
          collection.new([@mock_action]).dependencies!
        end
      end

      should "not raise an exception if they are met" do
        assert_nothing_raised do
          collection.new([@mock_action, @mock_action2]).dependencies!
        end
      end
    end

    context "that are before and after an action" do
      setup do
        @mock_action.stubs(:precedes).returns([MockActionOther])
        @mock_action.stubs(:follows).returns([MockActionOther])
      end

      should "raise an exception if they are met" do
        assert_raise Vagrant::Actions::DependencyNotSatisfiedException do
          collection.new([@mock_action2, @mock_action]).dependencies!
        end
      end

      should "not raise and exception if they are met" do
        assert_nothing_raised do
          collection.new([@mock_action2, @mock_action, @mock_action2]).dependencies!
        end
      end
    end
  end

  context "klasses" do
    should "return a list of the collection element's classes" do
      @action = mock('action')
      assert_equal collection.new([@action]).klasses, [@action.class]
      assert_equal collection.new([@action, 1.0, "foo"]).klasses, [@action.class, Float, String]
    end
  end

  def collection; Vagrant::Actions::Collection end
end
