require 'test_helper'

class CheckAccessibleVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::CheckAccessible
  end

  context "calling" do
    setup do
      @app, @env = action_env
      @instance = @klass.new(@app, @env)
    end

    should "continue up the chain if the VM is nil" do
      @env["vm"] = nil

      @app.expects(:call).once

      assert_nothing_raised {
        @instance.call(@env)
      }
    end

    should "continue up the chain if the VM is not created" do
      @env["vm"] = mock("vm")
      @env["vm"].stubs(:created?).returns(false)

      @app.expects(:call).once

      assert_nothing_raised {
        @instance.call(@env)
      }
    end

    should "continue up the chain if the VM is created and accessible" do
      @env["vm"] = mock("vm")
      @env["vm"].stubs(:created?).returns(true)
      @env["vm"].stubs(:vm).returns(mock("real_vm"))
      @env["vm"].vm.stubs(:accessible?).returns(true)

      @app.expects(:call).once

      assert_nothing_raised {
        @instance.call(@env)
      }
    end

    should "fail if the VM is not accessible" do
      @env["vm"] = mock("vm")
      @env["vm"].stubs(:created?).returns(true)
      @env["vm"].stubs(:vm).returns(mock("real_vm"))
      @env["vm"].vm.stubs(:accessible?).returns(false)

      @app.expects(:call).never

      assert_raises(Vagrant::Errors::VMInaccessible) {
        @instance.call(@env)
      }
    end
  end
end
