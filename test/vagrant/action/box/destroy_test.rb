require "test_helper"

class DestroyBoxActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Box::Destroy
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

    should "delete the box directory" do
      seq = sequence("seq")
      FileUtils.expects(:rm_rf).with(@env["box"].directory).in_sequence(seq)
      @app.expects(:call).with(@env).once.in_sequence(seq)
      @instance.call(@env)
    end
  end
end
