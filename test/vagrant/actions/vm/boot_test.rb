require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class BootActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Boot)
    @runner.stubs(:invoke_callback)
  end

  context "preparing" do
    should "add the root shared folder" do
      @runner.env.config.vm.expects(:share_folder).with("v-root", @runner.env.config.vm.project_directory, @runner.env.root_path).once
      @action.prepare
    end
  end

  context "execution" do
    should "invoke the 'boot' around callback" do
      boot_seq = sequence("boot_seq")
      @runner.expects(:invoke_around_callback).with(:boot).once.in_sequence(boot_seq).yields
      @action.expects(:boot).in_sequence(boot_seq)
      @action.expects(:wait_for_boot).returns(true).in_sequence(boot_seq)
      @action.execute!
    end

    should "error and exit if the bootup failed" do
      fail_boot_seq = sequence("fail_boot_seq")
      @action.expects(:boot).once.in_sequence(fail_boot_seq)
      @action.expects(:wait_for_boot).returns(false).in_sequence(fail_boot_seq)
      @action.expects(:error_and_exit).with(:vm_failed_to_boot).once.in_sequence(fail_boot_seq)
      @action.execute!
    end
  end

  context "booting" do
    should "start the VM in specified mode" do
      mode = mock("boot_mode")
      @runner.env.config.vm.boot_mode = mode
      @vm.expects(:start).with(mode).once
      @action.boot
    end
  end

  context "waiting for boot" do
    should "repeatedly ping the SSH port and return false with no response" do
      seq = sequence('pings')
      @runner.env.ssh.expects(:up?).times(@runner.env.config.ssh.max_tries.to_i - 1).returns(false).in_sequence(seq)
      @runner.env.ssh.expects(:up?).once.returns(true).in_sequence(seq)
      assert @action.wait_for_boot(0)
    end

    should "ping the max number of times then just return" do
      @runner.env.ssh.expects(:up?).times(Vagrant.config.ssh.max_tries.to_i).returns(false)
      assert !@action.wait_for_boot(0)
    end
  end
end
