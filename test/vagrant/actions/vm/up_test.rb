require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class UpActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Up)
  end

  context "sub-actions" do
    setup do
      @runner.stubs(:created?).returns(false)

      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      @default_order = [Vagrant::Actions::VM::Import, Vagrant::Actions::VM::Start]

      @dotfile_path = "foo"
      @runner.env.stubs(:dotfile_path).returns(@dotfile_path)
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.each do |action|
        @runner.expects(:add_action).with(action, @action.options).once.in_sequence(default_seq)
      end
    end

    should "raise an ActionException if a dotfile exists but is not a file" do
      File.expects(:file?).with(@runner.env.dotfile_path).returns(false)
      assert_raises(Vagrant::Actions::ActionException) {
        @action.prepare
      }
    end

    should "not raise an ActionException if dotfile doesn't exist" do
      setup_action_expectations
      File.stubs(:exist?).returns(false)
      assert_nothing_raised { @action.prepare }
    end

    should "not raise an ActionException if dotfile exists but is a file" do
      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      setup_action_expectations
      assert_nothing_raised { @action.prepare }
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end

    should "add in the action to move hard drive if config is set" do
      env = mock_environment do |config|
        File.expects(:directory?).with("foo").returns(true)
        config.vm.hd_location = "foo"
      end

      @runner.stubs(:env).returns(env)
      env.stubs(:dotfile_path).returns(@dotfile_path)

      @default_order.insert(0, Vagrant::Actions::VM::MoveHardDrive)
      setup_action_expectations
      @action.prepare
    end
  end

  context "callbacks" do
    should "call update dotfile and mac address setup after import" do
      boot_seq = sequence("boot")
      @action.expects(:update_dotfile).once.in_sequence(boot_seq)
      @action.expects(:setup_mac_address).once.in_sequence(boot_seq)
      @action.expects(:check_guest_additions).once.in_sequence(boot_seq)
      @action.after_import
    end
  end

  context "updating the dotfile" do
    should "call update dotfile on the VM's environment" do
      @runner.stubs(:uuid)
      @runner.env.expects(:update_dotfile).once
      @action.update_dotfile
    end
  end

  context "setting up MAC address" do
    should "match the mac address with the base" do
      nic = mock("nic")
      nic.expects(:mac_address=).once

      @vm.expects(:network_adapters).returns([nic]).once
      @vm.expects(:save).once

      @action.setup_mac_address
    end
  end
end
