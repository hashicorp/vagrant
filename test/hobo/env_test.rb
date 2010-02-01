require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase
  def dot_file_expectation
    File.expects(:exists?).at_least_once.returns(true)
    File.expects(:open).with(dotfile, 'r').returns(['foo'])
  end

  def config_file_expectation
    YAML.expects(:load_file).with(Hobo::Env::CONFIG.keys.first).returns(hobo_mock_config)
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

  context "initial load" do
    test "load! should load the config and set the persisted_uid" do
      Hobo::Env.expects(:load_config!).once
      Hobo::Env.expects(:load_vm!).once
      Hobo::Env.expects(:load_root_path!).once
      Hobo::Env.load!
    end
  end

  context "loading config" do
    setup do
      @handler = Hobo::Env
      @ensure = Hobo::Env::ENSURE
      Hobo.config! nil
    end

    test "should not create any directories if they exist"  do
      File.expects(:exists?).times(@ensure[:dirs].length).returns(true)
      Dir.expects(:mkdir).never
      @handler.ensure_directories
    end

    test "should not copy any files if they exist" do
      File.expects(:exists?).times(@ensure[:files].length).returns(true)
      File.expects(:copy).never
      @handler.ensure_files
    end

    test "should create the ensured directories if they don't exist" do
      file_seq = sequence("file_seq")

      @ensure[:dirs].each do |dir|
        File.expects(:exists?).returns(false).in_sequence(file_seq)
        Dir.expects(:mkdir).with(dir).in_sequence(file_seq)
      end

      @handler.ensure_directories
    end

    test "should create the ensured files if they don't exist" do
      file_seq = sequence("file_seq")

      @ensure[:files].each do |target, default|
        File.expects(:exists?).with(target).returns(false).in_sequence(file_seq)
        File.expects(:copy).with(File.join(PROJECT_ROOT, default), target).in_sequence(file_seq)
      end

      @handler.ensure_files
    end

    test "should load of the default" do
      config_file_expectation
      @handler.load_config!
      assert_equal Hobo.config[:ssh], hobo_mock_config[:ssh]
    end

    test "Hobo.config should be nil unless loaded" do
      assert_equal Hobo.config, nil
    end
  end

  context "persisting the VM into a file" do
    setup do
      Hobo.config! hobo_mock_config
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
    setup do
      Hobo.config! hobo_mock_config
    end

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
      assert_equal File.join(Hobo::Env.root_path, hobo_mock_config[:dotfile_name]), Hobo::Env.dotfile_path
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
