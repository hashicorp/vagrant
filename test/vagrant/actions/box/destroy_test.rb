require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DestroyBoxActionTest < Test::Unit::TestCase
  setup do
    @name = "foo"
    @dir = "foo"
    @runner, @vm, @action = mock_action(Vagrant::Actions::Box::Destroy)
    @runner.stubs(:directory).returns(@dir)
  end

  context "executing" do
    should "rm_rf the directory" do
      FileUtils.expects(:rm_rf).with(@dir).once
      @action.execute!
    end
  end
end
