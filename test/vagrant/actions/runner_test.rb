require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ActionRunnerTest < Test::Unit::TestCase
  class MockAction; end
  class MockActionOther; end

  def mock_fake_action(action_klass = nil, runner = nil)
    action = action_klass ? action_klass.new(runner) : mock("action")
    action.stubs(:prepare)
    action.stubs(:execute!)
    action.stubs(:cleanup)
    stub_default_action_dependecies(action)
    action
  end

  context "callbacks" do
    setup do
      @runner = Vagrant::Actions::Runner.new
    end

    context "around callbacks" do
      should "invoke before/after_name for around callbacks" do
        block_obj = mock("block_obj")
        around_seq = sequence("around_seq")
        @runner.expects(:invoke_callback).with(:before_foo).once.in_sequence(around_seq)
        block_obj.expects(:foo).once.in_sequence(around_seq)
        @runner.expects(:invoke_callback).with(:after_foo).once.in_sequence(around_seq)

        @runner.invoke_around_callback(:foo) do
          block_obj.foo
        end
      end

      should "forward arguments to invoke_callback" do
        @runner.expects(:invoke_callback).with(:before_foo, "foo").once
        @runner.expects(:invoke_callback).with(:after_foo, "foo").once
        @runner.invoke_around_callback(:foo, "foo") do; end
      end
    end

    should "not invoke callback on actions which don't respond to it" do
      action = mock("action")
      action.stubs(:respond_to?).with(:foo).returns(false)
      action.expects(:foo).never

      assert_nothing_raised do
        @runner.actions << action
        @runner.invoke_callback(:foo)
      end
    end

    should "invoke callback on actions which do respond to the method" do
      action = mock("action")
      action.expects(:foo).once

      @runner.actions << action
      @runner.invoke_callback(:foo)
    end

    should "collect all the results and return them as an array" do
      result = []
      3.times do |i|
        action = mock("action#{i}")
        action.expects(:foo).returns("foo#{i}").once

        @runner.actions << action
        result << "foo#{i}"
      end

      assert_equal result, @runner.invoke_callback(:foo)
    end
  end

  context "finding actions" do
    setup do
      @runner = Vagrant::Actions::Runner.new
    end

    should "return nil if the action could not be found" do
      assert_nil @runner.find_action(Vagrant::Actions::VM::Export)
    end

    should "return the first instance of the action found" do
      @runner.add_action(Vagrant::Actions::VM::Export)
      @runner.add_action(Vagrant::Actions::VM::Export)

      assert @runner.actions[0].equal?(@runner.find_action(Vagrant::Actions::VM::Export))
    end
  end

  context "adding actions" do
    setup do
      @runner = Vagrant::Actions::Runner.new
    end

    should "initialize the action when added" do
      action_klass = mock("action_class")
      action_inst = mock("action_inst")
      action_klass.expects(:new).once.returns(action_inst)
      @runner.add_action(action_klass)
      assert_equal 1, @runner.actions.length
    end

    should "initialize the action with given arguments when added" do
      action_klass = mock("action_class")
      action_klass.expects(:new).with(@runner, "foo", "bar").once
      @runner.add_action(action_klass, "foo", "bar")
    end
  end

  context "class method execute" do
    should "run actions on class method execute!" do
      vm = mock("vm")
      execute_seq = sequence("execute_seq")
      Vagrant::Actions::Runner.expects(:new).returns(vm).in_sequence(execute_seq)
      vm.expects(:add_action).with("foo").in_sequence(execute_seq)
      vm.expects(:execute!).once.in_sequence(execute_seq)

      Vagrant::Actions::Runner.execute!("foo")
    end

    should "forward arguments to add_action on class method execute!" do
      vm = mock("vm")
      execute_seq = sequence("execute_seq")
      Vagrant::Actions::Runner.expects(:new).returns(vm).in_sequence(execute_seq)
      vm.expects(:add_action).with("foo", "bar", "baz").in_sequence(execute_seq)
      vm.expects(:execute!).once.in_sequence(execute_seq)

      Vagrant::Actions::Runner.execute!("foo", "bar", "baz")
    end
  end

  context "instance method execute" do
    setup do
      @runner = Vagrant::Actions::Runner.new
      @runner.stubs(:action_klasses).returns([Vagrant::Actions::Base])
    end

    should "clear the actions and run a single action if given to execute!" do
      action = mock("action")
      run_action = mock("action_run")
      stub_default_action_dependecies(run_action)
      run_class = mock("run_class")
      run_class.expects(:new).once.returns(run_action)
      @runner.actions << action

      [:prepare, :execute!, :cleanup].each do |method|
        action.expects(method).never
        run_action.expects(method).once
      end

      @runner.execute!(run_class)
    end

    should "clear actions after running execute!" do
      @runner.actions << mock_fake_action
      assert !@runner.actions.empty? # sanity
      @runner.execute!
      assert @runner.actions.empty?
    end

    should "run #prepare on all actions, then #execute!" do
      action_seq = sequence("action_seq")
      actions = []
      [MockAction, MockActionOther].each_with_index do |klass, i|
        action = mock("action#{i}")
        action.expects(:class).returns(klass)
        stub_default_action_dependecies(action)
        @runner.actions << action
        actions << action
      end

      [:prepare, :execute!, :cleanup].each do |method|
        actions.each do |action|
          action.expects(method).once.in_sequence(action_seq)
        end
      end

      @runner.execute!
    end

    context "exceptions" do
      setup do
        @actions = [MockAction, MockActionOther].map do |klass|
          action = mock_fake_action
          action.expects(:class).returns(klass)
          action.stubs(:rescue)
          @runner.actions << action
          action
        end

        @exception = Exception.new
      end

      should "call #rescue on each action if an exception is raised during execute!" do
        @actions.each do |a|
          a.expects(:rescue).with(@exception).once
        end

        @actions[0].stubs(:execute!).raises(@exception)

        @runner.expects(:error_and_exit).never
        assert_raises(Exception) { @runner.execute! }
      end

      should "call #rescue on each action if an exception is raised during prepare" do
        @actions.each do |a|
          a.expects(:rescue).with(@exception).once
        end

        @actions[0].stubs(:prepare).raises(@exception)

        @runner.expects(:error_and_exit).never
        assert_raises(Exception) { @runner.execute! }
      end

      should "call error_and_exit if it is an ActionException" do
        @exception = Vagrant::Actions::ActionException.new("foo")
        @actions[0].stubs(:prepare).raises(@exception)

        @runner.expects(:error_and_exit).with(@exception.key, @exception.data).once
        @runner.execute!
      end
    end
  end

  context "actions" do
    setup do
      @runner = Vagrant::Actions::Runner.new
    end

    should "setup actions to be an array" do
      assert_nil @runner.instance_variable_get(:@actions)
      actions = @runner.actions
      assert actions.is_a?(Array)
      assert actions.equal?(@runner.actions)
    end

    should "be empty initially" do
      assert @runner.actions.empty?
    end
  end

  context "duplicate action exceptions" do
    setup do
      @runner = Vagrant::Actions::Runner.new
    end

    should "should be raised when a duplicate is added" do
      action = mock_fake_action
      2.times {@runner.actions << action }
      assert_raise Vagrant::Actions::DuplicateActionException do
        @runner.execute!
      end
    end

    should "should not be raise when no duplicate actions are present" do
      @runner.actions << mock_fake_action(Vagrant::Actions::Base, @runner)
      @runner.actions << mock_fake_action(Vagrant::Actions::VM::Halt, @runner)

      assert_nothing_raised { @runner.execute! }
    end

    should "should not raise when a single action is specified" do
      assert_nothing_raised { @runner.execute!(Vagrant::Actions::Base) }
    end
  end
end
