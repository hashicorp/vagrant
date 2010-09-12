require "test_helper"

class HaltVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Halt
    @app, @env = action_env

    @vm = mock("vm")
    @vm.stubs(:name).returns("foo")
    @vm.stubs(:ssh).returns(mock("ssh"))
    @vm.stubs(:system).returns(mock("system"))
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "initializing" do
    should "merge in the given options" do
      @klass.new(@app, @env, :foo => :bar)
      assert_equal :bar, @env[:foo]
    end
  end

  context "calling" do
    setup do
      @vm.stubs(:created?).returns(true)
      @internal_vm.stubs(:running?).returns(true)

      @vm.system.stubs(:halt)
      @internal_vm.stubs(:stop)
      @internal_vm.stubs(:state).returns(:powered_off)
    end

    should "do nothing if VM is not created" do
      @internal_vm.stubs(:created?).returns(false)
      @vm.system.expects(:halt).never
      @internal_vm.expects(:stop).never
      @app.expects(:call).once

      @instance.call(@env)
    end

    should "do nothing if VM not running" do
      @internal_vm.stubs(:running?).returns(false)
      @vm.system.expects(:halt).never
      @internal_vm.expects(:stop).never
      @app.expects(:call).once

      @instance.call(@env)
    end

    should "halt with the system and NOT force VM to stop if powered off" do
      @internal_vm.expects(:state).with(true).returns(:powered_off)
      @vm.system.expects(:halt).once
      @internal_vm.expects(:stop).never
      @app.expects(:call).once

      @instance.call(@env)
    end

    should "halt with the system and force VM to stop if NOT powered off" do
      @internal_vm.expects(:state).with(true).returns(:running)
      @vm.system.expects(:halt).once
      @internal_vm.expects(:stop).once
      @app.expects(:call).once

      @instance.call(@env)
    end

    should "not call halt on the system if forcing" do
      @env[:force] = true
      @vm.system.expects(:halt).never
      @instance.call(@env)
    end
  end
end
