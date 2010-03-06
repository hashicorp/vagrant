require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DestroyActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Destroy)
    mock_config
  end

  context "executing" do
    setup do
      @vm.stubs(:destroy)
    end

    should "invoke an around callback around the destroy" do
      @mock_vm.expects(:invoke_around_callback).with(:destroy).once
      @action.execute!
    end

    should "destroy VM and attached images" do
      @vm.expects(:destroy).with(:destroy_image => true).once
      @action.execute!
    end
  end
end
