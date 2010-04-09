require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class UnpackageBoxActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::Box::Unpackage)
    @runner.stubs(:name).returns("foo")
    @runner.stubs(:temp_path).returns("bar")

    @runner.env.stubs(:boxes_path).returns("bar")
  end

  context "executing" do
    setup do
      @runner.stubs(:invoke_around_callback).yields
    end

    should "execute the proper actions in the proper order" do
      exec_seq = sequence("exec_seq")
      @action.expects(:setup_box_dir).in_sequence(exec_seq)
      @action.expects(:decompress).in_sequence(exec_seq)
      @action.execute!
    end

    should "execute it in a around block" do
      @runner.expects(:invoke_around_callback).with(:unpackage).once
      @action.execute!
    end
  end

  context "rescuing" do
    setup do
      File.stubs(:directory?).returns(false)
      FileUtils.stubs(:rm_rf)

      @box_dir = mock("foo")
      @action.stubs(:box_dir).returns(@box_dir)
    end

    should "do nothing if a directory doesn't exist" do
      FileUtils.expects(:rm_rf).never
      @action.rescue(nil)
    end

    should "remove the box directory if it exists" do
      File.expects(:directory?).returns(true)
      FileUtils.expects(:rm_rf).with(@box_dir).once
      @action.rescue(nil)
    end
  end

  context "box directory" do
    should "return the runner directory" do
      result = mock("object")
      @runner.expects(:directory).once.returns(result)
      assert result.equal?(@action.box_dir)
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
      @action.expects(:error_and_exit).with(:box_already_exists, :box_name => @runner.name).once
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
      Archive::Tar::Minitar.stubs(:unpack)
    end

    should "change to the box directory" do
      Dir.expects(:chdir).with(@box_dir)
      @action.decompress
    end

    should "open the tar file within the new directory, and extract it all" do
      Archive::Tar::Minitar.expects(:unpack).with(@runner.temp_path, @box_dir).once
      @action.decompress
    end
  end
end
