require "test_helper"

class ExportVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Export
    @app, @env = action_env

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    setup do
      @internal_vm.stubs(:powered_off?).returns(true)
    end

    should "call the proper methods then continue chain" do
      seq = sequence("seq")
      @instance.expects(:setup_temp_dir).in_sequence(seq)
      @instance.expects(:export).in_sequence(seq)
      @app.expects(:call).with(@env).in_sequence(seq)
      @instance.expects(:recover).in_sequence(seq).with(@env)

      @instance.call(@env)
    end

    should "halt the chain if not powered off" do
      @internal_vm.stubs(:powered_off?).returns(false)
      @instance.expects(:setup_temp_dir).never
      @instance.expects(:export).never
      @app.expects(:call).with(@env).never
      @instance.expects(:recover).never

      assert_raises(Vagrant::Errors::VMPowerOffToPackage) {
        @instance.call(@env)
      }
    end
  end

  context "cleaning up" do
    setup do
      @temp_dir = "foo"
      @instance.stubs(:temp_dir).returns(@temp_dir)
      File.stubs(:exist?).returns(true)
    end

    should "delete the temporary file if it exists" do
      File.expects(:unlink).with(@temp_dir).once
      @instance.recover(nil)
    end

    should "not delete anything if it doesn't exist" do
      File.stubs(:exist?).returns(false)
      File.expects(:unlink).never
      @instance.recover(nil)
    end
  end

  context "setting up the temporary directory" do
    setup do
      @time_now = Time.now.to_i.to_s
      Time.stubs(:now).returns(@time_now)

      @temp_dir = @env.env.tmp_path.join(@time_now)
      FileUtils.stubs(:mkpath)
    end

    should "create the temporary directory using the current time" do
      FileUtils.expects(:mkpath).with(@temp_dir).once
      @instance.setup_temp_dir
    end

    should "set to the environment" do
      @instance.setup_temp_dir
      assert_equal @temp_dir, @env["export.temp_dir"]
      assert_equal @temp_dir, @instance.temp_dir
    end
  end

  context "exporting" do
    setup do
      @ovf_path = mock("ovf_path")
      @instance.stubs(:ovf_path).returns(@ovf_path)
    end

    should "call export on the runner with the ovf path" do
      @internal_vm.expects(:export).with(@ovf_path).once
      @instance.export
    end
  end

  context "path to OVF file" do
    setup do
      @temp_dir = "foo"
      @env["export.temp_dir"] = @temp_dir
    end

    should "be the temporary directory joined with the OVF filename" do
      assert_equal File.join(@temp_dir, @env.env.config.vm.box_ovf), @instance.ovf_path
    end
  end
end
