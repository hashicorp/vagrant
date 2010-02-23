require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class UnpackageBoxActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::Box::Unpackage)
    @runner.stubs(:name).returns("foo")
    @runner.stubs(:temp_path).returns("bar")
    mock_config

    Vagrant::Env.stubs(:boxes_path).returns("bar")
  end

  context "executing" do
    should "execute the proper actions in the proper order" do
      exec_seq = sequence("exec_seq")
      @action.expects(:setup_box_dir).in_sequence(exec_seq)
      @action.expects(:decompress).in_sequence(exec_seq)
      @action.execute!
    end
  end

  context "box directory" do
    setup do
      @box_dir = File.join(Vagrant::Env.boxes_path, @runner.name)
    end

    should "return the boxes_path joined with the name" do
      assert_equal @box_dir, @action.box_dir
    end
  end

  context "setting up the box directory" do
    setup do
      File.stubs(:directory?).returns(false)
      FileUtils.stubs(:mkdir_p)

      @box_dir = "foo"
      @action.stubs(:box_dir).returns(@box_dir)
    end

    should "error and exit if the directory exists" do
      File.expects(:directory?).returns(true)
      @action.expects(:error_and_exit).once
      @action.setup_box_dir
    end

    should "create the directory" do
      FileUtils.expects(:mkdir_p).with(@box_dir).once
      @action.setup_box_dir
    end
  end

  context "decompressing" do
    setup do
      @box_dir = "foo"

      @action.stubs(:box_dir).returns(@box_dir)
      Dir.stubs(:chdir).yields
    end

    should "change to the box directory" do
      Dir.expects(:chdir).with(@box_dir)
      @action.decompress
    end

    should "open the tar file within the new directory, and extract it all" do
      @tar = mock("tar")
      @tar.expects(:extract_all).once
      Tar.expects(:open).with(@runner.temp_path, anything, anything, anything).yields(@tar)
      @action.decompress
    end
  end
end
