require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class PackageActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::Package)
    @action.to = '/foo/bar/baz'
    @action.name = 'bing'
    mock_config
  end

  context "executing" do
    setup do
      @tar_path = "foo"

      @action.stubs(:compress)
      @action.stubs(:clean)
      @action.stubs(:tar_path).returns(@tar_path)
    end

    should "compress and remove the working directory" do
      package_seq = sequence("package_seq")
      @action.expects(:compress).in_sequence(package_seq)
      @action.expects(:clean).in_sequence(package_seq)
      @action.execute!
    end

    should "return the tar path" do
      assert_equal @tar_path, @action.execute!
    end
  end

  context "cleaning up" do
    setup do
      @working_dir = "foo"
      @action.stubs(:working_dir).returns(@working_dir)
    end

    should "remove the working directory" do
      FileUtils.expects(:rm_r).with(@working_dir).once
      @action.clean
    end
  end

  context "working directory" do
    should "create the directory" do
      FileUtils.expects(:mkpath).with(File.join(@action.to, @action.name))
      @action.working_dir
    end
  end

  context "tar path" do
    should "be the working directory with the extension attached" do
      @action.expects(:working_dir).returns("foo")
      assert_equal "foo#{Vagrant.config.package.extension}", @action.tar_path
    end
  end

  # TODO test compression once its finished
end
