require "test_helper"

class SetEnvActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Env::Set
    @app, @env = action_env
    @env.clear
  end

  should "merge in the given options" do
    @klass.new(@app, @env, :foo => :bar)
    assert_equal :bar, @env[:foo]
  end

  should "not merge in anything if not given" do
    @klass.new(@app, @env)
    assert @env.empty?
  end

  should "just continue the chain" do
    @app.expects(:call).with(@env)
    @klass.new(@app, @env).call(@env)
  end
end
