require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DestroyActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Destroy)
  end

  context "executing" do
    should "invoke an around callback around the destroy" do
      @runner.expects(:invoke_around_callback).with(:destroy).once
      @action.execute!
    end

    should "destroy VM and clear persist" do
      @runner.stubs(:invoke_around_callback).yields
      clear_seq = sequence("clear")
      @action.expects(:destroy_vm).in_sequence(clear_seq)
      @action.expects(:update_dotfile).in_sequence(clear_seq)
      @action.execute!
    end
  end

  context "destroying the VM" do
    should "destroy VM and attached images" do
      @vm.expects(:destroy).with(:destroy_medium => :delete).once
      @runner.expects(:vm=).with(nil).once
      @action.destroy_vm
    end
  end

  context "updating the dotfile" do
    should "update the environment dotfile" do
      @runner.env.expects(:update_dotfile).once
      @action.update_dotfile
    end
  end
end
