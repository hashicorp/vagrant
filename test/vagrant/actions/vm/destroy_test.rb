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
      @action.expects(:depersist).in_sequence(clear_seq)
      @action.execute!
    end
  end

  context "destroying the VM" do
    should "destroy VM and attached images" do
      @vm.expects(:destroy).with(:destroy_medium => :delete).once
      @action.destroy_vm
    end
  end

  context "depersisting" do
    should "call depersist_vm on Env" do
      @runner.env.expects(:depersist_vm).once
      @action.depersist
    end
  end
end
