require "test_helper"

class VerifyBoxActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Box::Verify
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env["vm"] = @vm
    @env["box"] = Vagrant::Box.new(mock_environment, "foo")

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    setup do
      @env.logger.stubs(:info)
    end

    should "continue fine if verification succeeds" do
      seq = sequence("seq")
      VirtualBox::Appliance.expects(:new).with(@env["box"].ovf_file).in_sequence(seq)
      @app.expects(:call).with(@env).once.in_sequence(seq)
      @instance.call(@env)
      assert !@env.error?
    end

    should "halt chain if verification fails" do
      VirtualBox::Appliance.expects(:new).with(@env["box"].ovf_file).raises(Exception)
      @app.expects(:call).with(@env).never
      @instance.call(@env)
      assert @env.error?
      assert_equal :box_verification_failed, @env.error.first
    end
  end
end
