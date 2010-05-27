require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class StartActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Start)

    @action.options[:provision] = true
  end

  context "sub-actions" do
    setup do
      @runner.stubs(:created?).returns(false)
      @vm.stubs(:saved?).returns(true)
      File.stubs(:file?).returns(true)
      File.stubs(:exist?).returns(true)
      @default_order = [Vagrant::Actions::VM::Boot]
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.flatten.each do |action|
        @runner.expects(:add_action).with(action, @action.options).once.in_sequence(default_seq)
      end
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end

    should "add customize to the beginning if its not saved" do
      @vm.expects(:saved?).returns(false)
      @default_order.unshift([Vagrant::Actions::VM::Customize, Vagrant::Actions::VM::ForwardPorts, Vagrant::Actions::VM::SharedFolders])
      setup_action_expectations
      @action.prepare
    end

    should "add do additional if VM is not created yet" do
      @runner.stubs(:vm).returns(nil)
      @default_order.unshift([Vagrant::Actions::VM::Customize, Vagrant::Actions::VM::ForwardPorts, Vagrant::Actions::VM::SharedFolders])
      setup_action_expectations
      @action.prepare
    end

    should "add provisioning if its enabled and not saved" do
      @vm.env.config.vm.provisioner = :chef_solo

      @runner.stubs(:vm).returns(nil)
      @default_order.unshift([Vagrant::Actions::VM::Customize, Vagrant::Actions::VM::ForwardPorts, Vagrant::Actions::VM::SharedFolders])
      @default_order << Vagrant::Actions::VM::Provision
      setup_action_expectations
      @action.prepare
    end
  end
end
