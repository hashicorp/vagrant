require "test_helper"

class DestroyBoxActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Box::Destroy
    @app, @env = action_env
    @env["box"] = Vagrant::Box.new(vagrant_env, "foo")

    @instance = @klass.new(@app, @env)
  end

  should "delete the box directory" do
    seq = sequence("seq")
    FileUtils.expects(:rm_rf).with(@env["box"].directory).in_sequence(seq)
    @app.expects(:call).with(@env).once.in_sequence(seq)
    @instance.call(@env)
  end
end
