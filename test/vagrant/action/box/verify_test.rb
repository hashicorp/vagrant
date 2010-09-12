require "test_helper"

class VerifyBoxActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Box::Verify
    @app, @env = action_env
    @env["box"] = Vagrant::Box.new(vagrant_env, "foo")

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "continue fine if verification succeeds" do
      seq = sequence("seq")
      VirtualBox::Appliance.expects(:new).with(@env["box"].ovf_file.to_s).in_sequence(seq)
      @app.expects(:call).with(@env).once.in_sequence(seq)
      assert_nothing_raised {
        @instance.call(@env)
      }
    end

    should "halt chain if verification fails" do
      VirtualBox::Appliance.expects(:new).with(@env["box"].ovf_file.to_s).raises(Exception)
      @app.expects(:call).with(@env).never
      assert_raises(Vagrant::Errors::BoxVerificationFailed) {
        @instance.call(@env)
      }
    end
  end
end
