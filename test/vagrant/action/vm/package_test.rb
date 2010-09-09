require "test_helper"

class PackageVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Package
    @app, @env = action_env
    @env["export.temp_dir"] = "foo"

    @instance = @klass.new(@app, @env)
  end

  should "be a subclass of general packaging middleware" do
    assert @instance.is_a?(Vagrant::Action::General::Package)
  end

  should "set the package directory then call parent" do
    @instance.expects(:general_call).once.with() do |env|
      assert env["package.directory"]
      assert_equal env["package.directory"], env["export.temp_dir"]
      true
    end

    @instance.call(@env)
  end
end
