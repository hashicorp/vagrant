require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class PackageActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Package, "bing", [])

    mock_config
  end

  context "initialization" do
    def get_action(*args)
      runner, vm, action = mock_action(Vagrant::Actions::VM::Package, *args)
      return action
    end

    should "make out_path 'package' by default if nil is given" do
      action = get_action(nil, [])
      assert_equal "package", action.out_path
    end

    should "make include files an empty array by default" do
      action = get_action("foo", nil)
      assert action.include_files.is_a?(Array)
      assert action.include_files.empty?
    end
  end

  context "executing" do
    setup do
      @action.stubs(:compress)
    end

    should "compress" do
      package_seq = sequence("package_seq")
      @action.expects(:compress).in_sequence(package_seq)
      @action.execute!
    end
  end

  context "tar path" do
    should "be the temporary directory with the name and extension attached" do
      pwd = "foo"
      FileUtils.stubs(:pwd).returns(pwd)
      assert_equal File.join(pwd, "#{@action.out_path}#{Vagrant.config.package.extension}"), @action.tar_path
    end
  end

  context "temp path" do
    setup do
      @export = mock("export")
      @action.expects(:export_action).returns(@export)
    end

    should "use the export action's temp dir" do
      path = mock("path")
      @export.expects(:temp_dir).returns(path)
      @action.temp_path
    end
  end

  context "compression" do
    setup do
      @tar_path = "foo"
      @action.stubs(:tar_path).returns(@tar_path)

      @temp_path = "foo"
      @action.stubs(:temp_path).returns(@temp_path)

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

    should "add included files when passed" do
      include_files = ['foo', 'bar']
      action = mock_action(Vagrant::Actions::VM::Package, "bing", include_files).last
      action.stubs(:temp_path).returns("foo")
      @tar.expects(:append_tree).with(".")
      include_files.each { |f| @tar.expects(:append_file).with(f) }
      action.compress
    end

    should "not add files when none are specified" do
      @tar.expects(:append_tree).with(".")
      @tar.expects(:append_file).never
      @action.compress
    end
  end

  context "preparing the action" do
    context "checking include files" do
      setup do
        @include_files = ['fooiest', 'booiest']
        @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Package, "bing", @include_files)
        @runner.stubs(:find_action).returns("foo")
      end

      should "check that all the include files exist" do
        @include_files.each do |file|
          File.expects(:exists?).with(file).returns(true)
        end
        @action.prepare
      end

      should "raise an exception when an include file does not exist" do
        File.expects(:exists?).once.returns(false)
        assert_raises(Vagrant::Actions::ActionException) { @action.prepare }
      end
    end

    context "loading export reference" do
      should "find and store a reference to the export action" do
        @export = mock("export")
        @runner.expects(:find_action).with(Vagrant::Actions::VM::Export).once.returns(@export)
        @action.prepare
        assert @export.equal?(@action.export_action)
      end

      should "raise an exception if the export action couldn't be found" do
        @runner.expects(:find_action).with(Vagrant::Actions::VM::Export).once.returns(nil)
        assert_raises(Vagrant::Actions::ActionException) { @action.prepare }
      end
    end
  end
end
