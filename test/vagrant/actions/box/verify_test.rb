require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class VerifyBoxActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::Box::Verify)
    @runner.stubs(:name).returns("foo")
    @runner.stubs(:temp_path).returns("bar")
  end

  context "executing" do
    should "execute the proper actions in the proper order" do
      exec_seq = sequence("exec_seq")
      @action.expects(:reload_configuration).in_sequence(exec_seq)
      @action.expects(:verify_appliance).in_sequence(exec_seq)
      @action.execute!
    end
  end

  context "reloading configuration" do
    should "set the new box, load box, then load config" do
      reload_seq = sequence("reload_seq")
      @runner.env.config.vm.expects(:box=).with(@runner.name).in_sequence(reload_seq)
      @runner.env.expects(:load_box!).in_sequence(reload_seq)
      @runner.env.expects(:load_config!).in_sequence(reload_seq)
      @action.reload_configuration
    end
  end

  context "verifying appliance" do
    setup do
      @runner.stubs(:ovf_file).returns("foo")
    end

    should "create new appliance and return true if succeeds" do
      VirtualBox::Appliance.expects(:new).with(@runner.ovf_file)
      assert_nothing_raised { @action.verify_appliance }
    end

    should "return false if an exception is raised" do
      VirtualBox::Appliance.expects(:new).with(@runner.ovf_file).raises(VirtualBox::Exceptions::FileErrorException)
      assert_raises(Vagrant::Actions::ActionException) { @action.verify_appliance }
    end
  end
end
