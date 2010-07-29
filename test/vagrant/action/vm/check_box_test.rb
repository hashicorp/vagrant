require 'test_helper'

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

    should "attempt to download box and continue if URL specified" do
      seq = sequence("seq")
      @env.env.config.vm.box_url = "bar"
      Vagrant::Box.expects(:find).returns(nil)
      Vagrant::Box.expects(:add).with(@env.env, @env["config"].vm.box, @env["config"].vm.box_url).in_sequence(seq)
      @env.env.expects(:load_box!).in_sequence(seq)
      @app.expects(:call).with(@env).once.in_sequence(seq)

      @instance.call(@env)
      assert !@env.error?
    end
  end
end
