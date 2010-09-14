require "test_helper"

class ImportVMActionTest < Test::Unit::TestCase
  setup do
    clean_paths
    vagrant_box("foo")

    @klass = Vagrant::Action::VM::Import
    @app, @env = action_env(vagrant_env(vagrantfile(<<-vf)))
      config.vm.box = "foo"
    vf

    @instance = @klass.new(@app, @env)

    @env.env.vm = Vagrant::VM.new(:env => @env.env, :name => "foobar")

    VirtualBox::VM.stubs(:import)

    @vm = mock("vm")
    @vm.stubs(:uuid).returns("foobar")
  end

  should "call import on VirtualBox with proper base" do
    VirtualBox::VM.expects(:import).once.with(@env.env.box.ovf_file.to_s).returns(@vm)
    @instance.call(@env)
  end

  should "call next in chain on success and set VM" do
    VirtualBox::VM.stubs(:import).returns(@vm)
    @app.expects(:call).with(@env).once
    @instance.call(@env)

    assert_equal @vm, @env["vm"].vm
  end

  should "mark environment erroneous and not continue chain on failure" do
    @app.expects(:call).never
    assert_raises(Vagrant::Errors::VMImportFailure) {
      @instance.call(@env)
    }
  end

  context "recovery" do
    setup do
      @env.env.vm.stubs(:created?).returns(true)
    end

    should "not run the destroy action on recover if error is a VagrantError" do
      @env["vagrant.error"] = Vagrant::Errors::VMImportFailure.new
      @env.env.actions.expects(:run).never
      @instance.recover(@env)
    end

    should "not run the destroy action on recover if VM is not created" do
      @env.env.vm.stubs(:created?).returns(false)
      @env.env.actions.expects(:run).never
      @instance.recover(@env)
    end

    should "run the destroy action on recover" do
      @env.env.vm.stubs(:created?).returns(true)
      @env.env.actions.expects(:run).with(:destroy).once
      @instance.recover(@env)
    end
  end
end
