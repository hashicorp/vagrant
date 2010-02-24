require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase
  def mock_persisted_vm(returnvalue="foovm")
    filemock = mock("filemock")
    filemock.expects(:read).returns("foo")
    Vagrant::VM.expects(:find).with("foo").returns(returnvalue)
    File.expects(:open).with(Vagrant::Env.dotfile_path).once.yields(filemock)
    Vagrant::Env.load_vm!
  end

  setup do
    mock_config
    Vagrant::Box.stubs(:find).returns("foo")
  end

  context "requiring a VM" do
    should "error and exit if no persisted VM was found" do
      assert_nil Vagrant::Env.persisted_vm
      Vagrant::Env.expects(:error_and_exit).once
      Vagrant::Env.require_persisted_vm
    end

    should "return and continue if persisted VM is found" do
      mock_persisted_vm
      Vagrant::Env.expects(:error_and_exit).never
      Vagrant::Env.require_persisted_vm
    end
  end

  context "loading home directory" do
    setup do
      @home_dir = File.expand_path(Vagrant.config.vagrant.home)

      File.stubs(:directory?).returns(true)
      FileUtils.stubs(:mkdir_p)
    end

    should "create each directory if it doesn't exist" do
      create_seq = sequence("create_seq")
      File.stubs(:directory?).returns(false)
      Vagrant::Env::HOME_SUBDIRS.each do |subdir|
        FileUtils.expects(:mkdir_p).with(File.join(@home_dir, subdir)).in_sequence(create_seq)
      end

      Vagrant::Env.load_home_directory!
    end

    should "not create directories if they exist" do
      File.stubs(:directory?).returns(true)
      FileUtils.expects(:mkdir_p).never
      Vagrant::Env.load_home_directory!
    end
  end

  context "loading config" do
    setup do
      @root_path = "/foo"
      Vagrant::Env.stubs(:root_path).returns(@root_path)
      Vagrant::Env.stubs(:box).returns(nil)
      File.stubs(:exist?).returns(false)
      Vagrant::Config.stubs(:execute!)
      Vagrant::Config.stubs(:reset!)
    end

    should "reset the configuration object" do
      Vagrant::Config.expects(:reset!).once
      Vagrant::Env.load_config!
    end

    should "load from the project root" do
      File.expects(:exist?).with(File.join(PROJECT_ROOT, "config", "default.rb")).once
      Vagrant::Env.load_config!
    end

    should "load from the root path" do
      File.expects(:exist?).with(File.join(@root_path, Vagrant::Env::ROOTFILE_NAME)).once
      Vagrant::Env.load_config!
    end

    should "not load from the box directory if it is nil" do
      Vagrant::Env.expects(:box).once.returns(nil)
      Vagrant::Env.load_config!
    end

    should "load from the box directory if it is not nil" do
      dir = "foo"
      box = mock("box")
      box.stubs(:directory).returns(dir)
      Vagrant::Env.expects(:box).twice.returns(box)
      File.expects(:exist?).with(File.join(dir, Vagrant::Env::ROOTFILE_NAME)).once
      Vagrant::Env.load_config!
    end

    should "load the files only if exist? returns true" do
      File.expects(:exist?).once.returns(true)
      Vagrant::Env.expects(:load).once
      Vagrant::Env.load_config!
    end

    should "not load the files if exist? returns false" do
      Vagrant::Env.expects(:load).never
      Vagrant::Env.load_config!
    end

    should "execute after loading" do
      File.expects(:exist?).once.returns(true)
      Vagrant::Env.expects(:load).once
      Vagrant::Config.expects(:execute!).once
      Vagrant::Env.load_config!
    end
  end

  context "initial load" do
    test "load! should load the config and set the persisted_uid" do
      Vagrant::Env.expects(:load_config!).once
      Vagrant::Env.expects(:load_vm!).once
      Vagrant::Env.expects(:load_root_path!).once
      Vagrant::Env.expects(:load_home_directory!).once
      Vagrant::Env.expects(:load_box!).once
      Vagrant::Env.load!
    end
  end

  context "persisting the VM into a file" do
    setup do
      mock_config
    end

    test "should save it to the dotfile path" do
      vm = mock("vm")
      vm.stubs(:uuid).returns("foo")

      filemock = mock("filemock")
      filemock.expects(:write).with(vm.uuid)
      File.expects(:open).with(Vagrant::Env.dotfile_path, 'w+').once.yields(filemock)
      Vagrant::Env.persist_vm(vm)
    end
  end

  context "loading the UUID out from the persisted file" do
    test "loading of the uuid from the dotfile" do
      mock_persisted_vm
      assert_equal 'foovm', Vagrant::Env.persisted_vm
    end

    test "uuid should be nil if dotfile didn't exist" do
      File.expects(:open).raises(Errno::ENOENT)
      Vagrant::Env.load_vm!
      assert_nil Vagrant::Env.persisted_vm
    end

    test "should build up the dotfile out of the root path and the dotfile name" do
      assert_equal File.join(Vagrant::Env.root_path, Vagrant.config.dotfile_name), Vagrant::Env.dotfile_path
    end
  end

  context "loading the root path" do
    test "should walk the parent directories looking for rootfile" do
      Vagrant::Env.expects(:error_and_exit).once

      paths = [
        Pathname.new("/foo/bar/baz"),
        Pathname.new("/foo/bar"),
        Pathname.new("/foo")
      ]

      search_seq = sequence("search_seq")
      paths.each do |path|
        File.expects(:exist?).with("#{path}/#{Vagrant::Env::ROOTFILE_NAME}").returns(false).in_sequence(search_seq)
      end

      assert_nil Vagrant::Env.load_root_path!(paths.first)
    end

    test "should print out an error and exit if not found" do
      path = Pathname.new("/")

      Vagrant::Env.expects(:error_and_exit).once
      Vagrant::Env.load_root_path!(path)
    end

    should "return false if suppress errors is set and no root path is found" do
      path = Pathname.new("/")

      Vagrant::Env.expects(:error_and_exit).never
      assert !Vagrant::Env.load_root_path!(path, :suppress_errors => true)
    end

    should "pipe suppress errors flag through recursion" do
      path = Pathname.new("/foo/bar/baz")
      File.expects(:exist?).times(3).returns(false)

      Vagrant::Env.expects(:error_and_exit).never
      assert !Vagrant::Env.load_root_path!(path, :suppress_errors => true)
    end

    test "should set the path for the rootfile" do
      path = "/foo"
      File.expects(:exist?).with("#{path}/#{Vagrant::Env::ROOTFILE_NAME}").returns(true)

      assert Vagrant::Env.load_root_path!(Pathname.new(path))
      assert_equal path, Vagrant::Env.root_path
    end
  end

  context "home directory paths" do
    should "return the expanded config for `home_path`" do
      assert_equal File.expand_path(Vagrant.config.vagrant.home), Vagrant::Env.home_path
    end

    should "return the home_path joined with tmp for a tmp path" do
      @home_path = "foo"
      Vagrant::Env.stubs(:home_path).returns(@home_path)
      assert_equal File.join(@home_path, "tmp"), Vagrant::Env.tmp_path
    end

    should "return the boxes path" do
      @home_path = "foo"
      Vagrant::Env.stubs(:home_path).returns(@home_path)
      assert_equal File.join(@home_path, "boxes"), Vagrant::Env.boxes_path
    end
  end

  context "loading box" do
    setup do
      @box = mock("box")

      Vagrant::Env.stubs(:load_config!)
    end

    should "set the box to what is found by the Box class" do
      Vagrant::Box.expects(:find).with(Vagrant.config.vm.box).once.returns(@box)
      Vagrant::Env.load_box!
      assert @box.equal?(Vagrant::Env.box)
    end

    should "load the config if a box is loaded" do
      Vagrant::Env.expects(:load_config!).once
      Vagrant::Box.expects(:find).returns(@box)
      Vagrant::Env.load_box!
    end

    should "not load the config if a box is not loaded" do
      Vagrant::Env.expects(:load_config!).never
      Vagrant::Box.expects(:find).returns(nil)
      Vagrant::Env.load_box!
    end
  end

  context "requiring boxes" do
    should "error and exit if no box is found" do
      Vagrant::Env.expects(:box).returns(nil)
      Vagrant::Env.expects(:error_and_exit).once
      Vagrant::Env.require_box
    end
  end
end
