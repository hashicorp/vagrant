require "test_helper"

class BootVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Boot
    @app, @env = action_env

    @vm = mock("vm")
    @vm.stubs(:ssh).returns(mock("ssh"))
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "run the proper methods on success" do
      boot_seq = sequence("boot_seq")
      @instance.expects(:boot).in_sequence(boot_seq)
      @instance.expects(:wait_for_boot).returns(true).in_sequence(boot_seq)
      @app.expects(:call).with(@env).once.in_sequence(boot_seq)
      @instance.call(@env)
    end

    should "error and halt chain if boot failed" do
      boot_seq = sequence("boot_seq")
      @instance.expects(:boot).in_sequence(boot_seq)
      @instance.expects(:wait_for_boot).returns(false).in_sequence(boot_seq)
      @app.expects(:call).never
      assert_raises(Vagrant::Errors::VMFailedToBoot) {
        @instance.call(@env)
      }
    end
  end

  context "booting" do
    should "start the VM in specified mode" do
      mode = mock("boot_mode")
      @env.env.config.vm.boot_mode = mode
      @internal_vm.expects(:start).with(mode).once
      @instance.boot
    end
  end

  context "waiting for boot" do
    should "repeatedly ping the SSH port and return false with no response" do
      seq = sequence('pings')
      @vm.ssh.expects(:up?).times(@env.env.config.ssh.max_tries.to_i - 1).returns(false).in_sequence(seq)
      @vm.ssh.expects(:up?).once.returns(true).in_sequence(seq)
      assert @instance.wait_for_boot
    end

    should "return right away if interrupted" do
      @env.interrupt!
      @vm.ssh.expects(:up?).times(1).returns(false)
      assert @instance.wait_for_boot
    end

    should "ping the max number of times then just return" do
      @vm.ssh.expects(:up?).times(@env.env.config.ssh.max_tries.to_i).returns(false)
      assert !@instance.wait_for_boot
    end
  end
end
