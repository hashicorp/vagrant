require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ActionRunnerTest < Test::Unit::TestCase
  def mock_fake_action
    action = mock("action")
    action.stubs(:prepare)
    action.stubs(:execute!)
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
    end

    should "clear the actions and run a single action if given to execute!" do
      action = mock("action")
      run_action = mock("action_run")
      run_class = mock("run_class")
      run_class.expects(:new).once.returns(run_action)
      @runner.actions << action

      [:prepare, :execute!].each do |method|
        action.expects(method).never
        run_action.expects(method).once
      end

      @runner.execute!(run_class)
    end

    should "clear actions after running execute!" do
      @runner.actions << mock_fake_action
      @runner.actions << mock_fake_action
      assert !@runner.actions.empty? # sanity
      @runner.execute!
      assert @runner.actions.empty?
    end

    should "run #prepare on all actions, then #execute!" do
      action_seq = sequence("action_seq")
      actions = []
      5.times do |i|
        action = mock("action#{i}")

        @runner.actions << action
        actions << action
      end

      [:prepare, :execute!].each do |method|
        actions.each do |action|
          action.expects(method).once.in_sequence(action_seq)
        end
      end

      @runner.execute!
    end

    context "exceptions" do
      setup do
        @actions = [mock_fake_action, mock_fake_action]
        @actions.each { |a| @runner.actions << a }

        @exception = Exception.new
      end

      should "call #rescue on each action if an exception is raised during execute!" do
        @actions.each do |a|
          a.expects(:rescue).with(@exception).once
        end

        @actions[0].stubs(:execute!).raises(@exception)
        assert_raises(Exception) { @runner.execute! }
      end

      should "call #rescue on each action if an exception is raised during prepare" do
        @actions.each do |a|
          a.expects(:rescue).with(@exception).once
        end

        @actions[0].stubs(:prepare).raises(@exception)
        assert_raises(Exception) { @runner.execute! }
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
end
