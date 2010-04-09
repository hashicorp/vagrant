require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ResumeActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Resume)
  end

  context "executing" do
    setup do
      @vm.stubs(:saved?).returns(true)
    end

    should "save the state of the VM" do
      @runner.expects(:start).once
      @action.execute!
    end

    should "raise an ActionException if the VM is not saved" do
      @vm.expects(:saved?).returns(false)
      @vm.expects(:start).never
      assert_raises(Vagrant::Actions::ActionException) {
        @action.execute!
      }
    end
  end
end
