require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase
  def dot_file_expectation
    File.expects(:exists?).at_least_once.returns(true)
    File.expects(:open).with(dotfile, 'r').returns(['foo'])
  end

  def dotfile(dir=Dir.pwd)
    "#{dir}/#{hobo_mock_config[:dotfile_name]}"
  end

  def mock_persisted_vm(returnvalue="foovm")
    filemock = mock("filemock")
    filemock.expects(:read).returns("foo")
    Hobo::VM.expects(:find).with("foo").returns(returnvalue)
    File.expects(:open).with(Hobo::Env.dotfile_path).once.yields(filemock)
    Hobo::Env.load_vm!
  end

  setup do
    Hobo::Env.stubs(:error_and_exit)
    hobo_mock_config
  end

  context "requiring a VM" do
    should "error and exit if no persisted VM was found" do
      assert_nil Hobo::Env.persisted_vm
      Hobo::Env.expects(:error_and_exit).once
      Hobo::Env.require_persisted_vm
    end

    should "return and continue if persisted VM is found" do
      mock_persisted_vm
      Hobo::Env.expects(:error_and_exit).never
      Hobo::Env.require_persisted_vm
    end
  end

  context "loading config" do
    setup do
      @root_path = "/foo"
      Hobo::Env.stubs(:root_path).returns(@root_path)
      File.stubs(:exist?).returns(false)
      Hobo::Config.stubs(:execute!)
    end

    should "load from the project root" do
      File.expects(:exist?).with(File.join(PROJECT_ROOT, "config", "default.rb")).once
      Hobo::Env.load_config!
    end

    should "load from the root path" do
      File.expects(:exist?).with(File.join(@root_path, Hobo::Env::HOBOFILE_NAME)).once
      Hobo::Env.load_config!
    end

    should "load the files only if exist? returns true" do
      File.expects(:exist?).once.returns(true)
      Hobo::Env.expects(:load).once
      Hobo::Env.load_config!
    end

    should "not load the files if exist? returns false" do
      Hobo::Env.expects(:load).never
      Hobo::Env.load_config!
    end

    should "execute after loading" do
      File.expects(:exist?).once.returns(true)
      Hobo::Env.expects(:load).once
      Hobo::Config.expects(:execute!).once
      Hobo::Env.load_config!
    end
  end

  context "initial load" do
    test "load! should load the config and set the persisted_uid" do
      Hobo::Env.expects(:load_config!).once
      Hobo::Env.expects(:load_vm!).once
      Hobo::Env.expects(:load_root_path!).once
      Hobo::Env.load!
    end
  end

  context "persisting the VM into a file" do
    setup do
      hobo_mock_config
    end

    test "should save it to the dotfile path" do
      vm = mock("vm")
      vm.stubs(:uuid).returns("foo")

      filemock = mock("filemock")
      filemock.expects(:write).with(vm.uuid)
      File.expects(:open).with(Hobo::Env.dotfile_path, 'w+').once.yields(filemock)
      Hobo::Env.persist_vm(vm)
    end
  end

  context "loading the UUID out from the persisted file" do
    test "loading of the uuid from the dotfile" do
      mock_persisted_vm
      assert_equal 'foovm', Hobo::Env.persisted_vm
    end

    test "uuid should be nil if dotfile didn't exist" do
      File.expects(:open).raises(Errno::ENOENT)
      Hobo::Env.load_vm!
      assert_nil Hobo::Env.persisted_vm
    end

    test "should build up the dotfile out of the root path and the dotfile name" do
      assert_equal File.join(Hobo::Env.root_path, Hobo.config.dotfile_name), Hobo::Env.dotfile_path
    end
  end

  context "loading the root path" do
    test "should walk the parent directories looking for hobofile" do
      paths = [
        Pathname.new("/foo/bar/baz"),
        Pathname.new("/foo/bar"),
        Pathname.new("/foo")
      ]

      search_seq = sequence("search_seq")
      paths.each do |path|
        File.expects(:exist?).with("#{path}/#{Hobo::Env::HOBOFILE_NAME}").returns(false).in_sequence(search_seq)
      end

      assert_nil Hobo::Env.load_root_path!(paths.first)
    end

    test "should print out an error and exit if not found" do
      path = Pathname.new("/")

      Hobo::Env.expects(:error_and_exit).once
      Hobo::Env.load_root_path!(path)
    end

    test "should set the path for the Hobofile" do
      path = "/foo"
      File.expects(:exist?).with("#{path}/#{Hobo::Env::HOBOFILE_NAME}").returns(true)
      Hobo::Env.load_root_path!(Pathname.new(path))

      assert_equal path, Hobo::Env.root_path
    end
  end
end
