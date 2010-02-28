require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VMTest < Test::Unit::TestCase
  setup do
    @mock_vm = mock("vm")
    mock_config

    @persisted_vm = mock("persisted_vm")
    Vagrant::Env.stubs(:persisted_vm).returns(@persisted_vm)

    Net::SSH.stubs(:start)
  end

  context "being an action runner" do
    should "be an action runner" do
      vm = Vagrant::VM.new
      assert vm.is_a?(Vagrant::Actions::Runner)
    end
  end

  context "finding a VM" do
    should "return nil if the VM is not found" do
      VirtualBox::VM.expects(:find).returns(nil)
      assert_nil Vagrant::VM.find("foo")
    end

    should "return a Vagrant::VM object for that VM otherwise" do
      VirtualBox::VM.expects(:find).with("foo").returns("bar")
      result = Vagrant::VM.find("foo")
      assert result.is_a?(Vagrant::VM)
      assert_equal "bar", result.vm
    end
  end

  context "vagrant VM instance" do
    setup do
      @vm = Vagrant::VM.new(@mock_vm)
    end

    context "packaging" do
      should "queue up the actions and execute" do
        out_path = mock("out_path")
        action_seq = sequence("actions")
        @vm.expects(:add_action).with(Vagrant::Actions::VM::Export).once.in_sequence(action_seq)
        @vm.expects(:add_action).with(Vagrant::Actions::VM::Package, out_path, []).once.in_sequence(action_seq)
        @vm.expects(:execute!).in_sequence(action_seq)
        @vm.package(out_path)
      end
    end

    context "destroying" do
      setup do
        @mock_vm.stubs(:running?).returns(false)
        @vm.stubs(:execute!)
      end

      should "destoy the VM along with images" do
        @mock_vm.expects(:destroy).with(:destroy_image => true).once
        @vm.destroy
      end

      should "stop the VM if its running" do
        @mock_vm.expects(:running?).returns(true)
        @mock_vm.expects(:destroy).with(:destroy_image => true).once
        @vm.expects(:execute!).with(Vagrant::Actions::VM::Stop).once
        @vm.destroy
      end
    end

    context "saving the state" do
      should "check if a VM is saved" do
        @mock_vm.expects(:saved?).returns("foo")
        assert_equal "foo", @vm.saved?
      end

      should "save state with errors raised" do
        @mock_vm.expects(:save_state).with(true).once
        @vm.save_state
      end
    end
  end
end
