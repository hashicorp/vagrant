require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class PackageActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Package, "bing")
    mock_config

    @temp_path = "temp_path"
    @action.temp_path = @temp_path
  end

  context "executing" do
    setup do
      @action.stubs(:compress)
      @action.stubs(:clean)
    end

    should "compress and remove the working directory" do
      package_seq = sequence("package_seq")
      @action.expects(:compress).in_sequence(package_seq)
      @action.expects(:clean).in_sequence(package_seq)
      @action.execute!
    end
  end

  context "cleaning up" do
    setup do
      @working_dir = "foo"
      @action.stubs(:working_dir).returns(@working_dir)
    end

    should "remove the working directory" do
      FileUtils.expects(:rm_r).with(@temp_path).once
      @action.clean
    end
  end

  context "tar path" do
    should "be the temporary directory with the name and extension attached" do
      pwd = "foo"
      FileUtils.stubs(:pwd).returns(pwd)
      assert_equal File.join(pwd, "#{@action.out_path}#{Vagrant.config.package.extension}"), @action.tar_path
    end
  end

  context "compression" do
    setup do
      @tar_path = "foo"
      @action.stubs(:tar_path).returns(@tar_path)

      @pwd = "bar"
      FileUtils.stubs(:pwd).returns(@pwd)
      FileUtils.stubs(:cd)

      @tar = mock("tar")
      Tar.stubs(:open).yields(@tar)
    end

    should "open the tar file with the tar path properly" do
      Tar.expects(:open).with(@tar_path, File::CREAT | File::WRONLY, 0644, Tar::GNU).once
      @action.compress
    end

    #----------------------------------------------------------------
    # Methods below this comment test the block yielded by Tar.open
    #----------------------------------------------------------------
    should "cd to the directory and append the directory" do
      compress_seq = sequence("compress_seq")
      FileUtils.expects(:pwd).once.returns(@pwd).in_sequence(compress_seq)
      FileUtils.expects(:cd).with(@temp_path).in_sequence(compress_seq)
      @tar.expects(:append_tree).with(".").in_sequence(compress_seq)
      FileUtils.expects(:cd).with(@pwd).in_sequence(compress_seq)
      @action.compress
    end

    should "pop back to the current directory even if an exception is raised" do
      cd_seq = sequence("cd_seq")
      FileUtils.expects(:cd).with(@temp_path).raises(Exception).in_sequence(cd_seq)
      FileUtils.expects(:cd).with(@pwd).in_sequence(cd_seq)

      assert_raises(Exception) {
        @action.compress
      }
    end
  end

  context "export callback to set temp path" do
    should "save to the temp_path directory" do
      foo = mock("foo")
      @action.set_export_temp_path(foo)
      assert foo.equal?(@action.temp_path)
    end
  end
end
