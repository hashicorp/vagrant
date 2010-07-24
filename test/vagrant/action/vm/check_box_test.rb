require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class CheckBoxVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::CheckBox
    @app, @env = mock_action_data
    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    setup do
      Vagrant::Box.stubs(:find)
    end

    should "return error if box not specified" do
      @env.env.config.vm.box = nil

      @app.expects(:call).never
      @instance.call(@env)

      assert @env.error?
      assert_equal :box_not_specified, @env.error.first
    end

    should "error if box does not exist and URL not specified" do
      @env.env.config.vm.box_url = nil
      Vagrant::Box.expects(:find).with(@env.env, @env["config"].vm.box).returns(nil)

      @app.expects(:call).never
      @instance.call(@env)

      assert @env.error?
      assert_equal :box_specified_doesnt_exist, @env.error.first
    end
  end
end
