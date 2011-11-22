require 'test_helper'

class CheckBoxVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::CheckBox
  end

  context "calling" do
    should "raise error if box not specified" do
      app, env = action_env(vagrant_env(vagrantfile(<<-vf)))
        config.vm.box = nil
      vf

      instance = @klass.new(app, env)
      app.expects(:call).never

      assert_raises(Vagrant::Errors::BoxNotSpecified) {
        instance.call(env)
      }
    end

    should "error if box does not exist and URL not specified" do
      app, env = action_env(vagrant_env(vagrantfile(<<-vf)))
        config.vm.box = "yo"
        config.vm.box_url = nil
      vf

      instance = @klass.new(app, env)
      app.expects(:call).never
      env.env.boxes.expects(:find).with(env["config"].vm.box).returns(nil)

      assert_raises(Vagrant::Errors::BoxSpecifiedDoesntExist) {
        instance.call(env)
      }
    end

    should "attempt to download box and continue if URL specified" do
      app, env = action_env(vagrant_env(vagrantfile(<<-vf)))
        config.vm.box = "yo"
        config.vm.box_url = "http://google.com"
      vf

      # Save this for later because the expecations below clobber it
      vms = env.env.vms

      instance = @klass.new(app, env)
      seq = sequence("seq")
      env.env.boxes.expects(:find).returns(nil)
      Vagrant::Box.expects(:add).with(env.env, env["config"].vm.box, env["config"].vm.box_url).in_sequence(seq)
      env.env.boxes.expects(:reload!).in_sequence(seq)
      vms.each do |name, vm|
        vm.env.expects(:reload_config!).in_sequence(seq)
      end
      app.expects(:call).with(env).once.in_sequence(seq)

      assert_nothing_raised {
        instance.call(env)
      }
    end
  end
end
