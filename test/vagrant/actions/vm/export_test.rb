require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ExportActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Export)
  end

  context "executing" do
    should "setup the temp dir then export" do
      exec_seq = sequence('execute')
      @action.expects(:setup_temp_dir).once.in_sequence(exec_seq)
      @action.expects(:export).once.in_sequence(exec_seq)
      @action.execute!
    end
  end

  context "setting up the temporary directory" do
    setup do
      @time_now = Time.now.to_i.to_s
      Time.stubs(:now).returns(@time_now)

      @tmp_path = "foo"
      @runner.env.stubs(:tmp_path).returns(@tmp_path)

      @temp_dir = File.join(@runner.env.tmp_path, @time_now)
      FileUtils.stubs(:mkpath)
    end

    should "create the temporary directory using the current time" do
      FileUtils.expects(:mkpath).with(@temp_dir).once
      @action.setup_temp_dir
    end

    should "set the temporary directory to the temp_dir variable" do
      @action.setup_temp_dir
      assert_equal @temp_dir, @action.temp_dir
    end
  end

  context "path to OVF file" do
    setup do
      @temp_dir = "foo"
      @action.stubs(:temp_dir).returns(@temp_dir)
    end

    should "be the temporary directory joined with the OVF filename" do
      assert_equal File.join(@temp_dir, @runner.env.config.vm.box_ovf), @action.ovf_path
    end
  end

  context "exporting" do
    setup do
      @ovf_path = mock("ovf_path")
      @action.stubs(:ovf_path).returns(@ovf_path)
    end

    should "call export on the runner with the ovf path" do
      @vm.expects(:export).with(@ovf_path).once
      @action.export
    end
  end

  context "cleanup" do
    setup do
      @temp_dir = "foo"
      @action.stubs(:temp_dir).returns(@temp_dir)
    end

    should "remove the temporary directory" do
      FileUtils.expects(:rm_r).with(@temp_dir).once
      @action.cleanup
    end

    should "not remove a directory if temp_dir is nil" do
      FileUtils.expects(:rm_r).never
      @action.stubs(:temp_dir).returns(nil)
      @action.cleanup
    end
  end

  context "rescue" do
    should "call cleanup method" do
      @action.expects(:cleanup).once
      @action.rescue(nil)
    end
  end
end
