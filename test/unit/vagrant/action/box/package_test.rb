require "test_helper"

class PackageBoxActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Box::Package
    @app, @env = action_env
    @env["box"] = Vagrant::Box.new(vagrant_env, "foo")

    @instance = @klass.new(@app, @env)
  end

  should "be a subclass of general packaging middleware" do
    assert @instance.is_a?(Vagrant::Action::General::Package)
  end

  should "set the package directory then call parent" do
    @instance.expects(:general_call).once.with() do |env|
      assert env["package.directory"]
      assert_equal env["package.directory"], @env["box"].directory
      true
    end

    @instance.call(@env)
  end
end
