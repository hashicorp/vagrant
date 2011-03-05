require "test_helper"

class ValidateGeneralActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::General::Validate
    @app, @env = action_env
  end

  should "initialize fine" do
    @klass.new(@app, @env)
  end

  should "validate and call up" do
    @instance = @klass.new(@app, @env)

    seq = sequence("seq")
    @env["config"].expects(:validate!).once.in_sequence(seq)
    @app.expects(:call).with(@env).once.in_sequence(seq)
    @instance.call(@env)
  end

  should "not validate if env says not to" do
    @env["validate"] = false
    @instance = @klass.new(@app, @env)

    seq = sequence("seq")
    @env["config"].expects(:validate!).never
    @app.expects(:call).with(@env).once.in_sequence(seq)
    @instance.call(@env)
  end
end
