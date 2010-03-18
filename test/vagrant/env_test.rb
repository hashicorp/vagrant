require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvTest < Test::Unit::TestCase
  def mock_persisted_vm(returnvalue="foovm")
    filemock = mock("filemock")
    filemock.expects(:read).returns("foo")
    Vagrant::VM.expects(:find).with("foo").returns(returnvalue)
    File.expects(:open).with(Vagrant::Env.dotfile_path).once.yields(filemock)
    File.expects(:file?).with(Vagrant::Env.dotfile_path).once.returns(true)
    Vagrant::Env.load_vm!
  end

  setup do
    mock_config
    Vagrant::Box.stubs(:find).returns("foo")
  end

  context "checking virtualbox version" do
    setup do
      VirtualBox::Command.stubs(:version).returns("3.1.4")
      VirtualBox::Global.stubs(:vboxconfig?).returns(true)
    end

    should "not error and exit if everything is good" do
      VirtualBox::Command.expects(:version).returns("3.1.4")
      VirtualBox::Global.expects(:vboxconfig?).returns(true)
      Vagrant::Env.expects(:error_and_exit).never
      Vagrant::Env.check_virtualbox!
    end

    should "error and exit if VirtualBox is not installed or detected" do
      Vagrant::Env.expects(:error_and_exit).once
      VirtualBox::Command.expects(:version).returns(nil)
      Vagrant::Env.check_virtualbox!
    end

    should "error and exit if VirtualBox is lower than version 3.1" do
      Vagrant::Env.expects(:error_and_exit).once
      VirtualBox::Command.expects(:version).returns("3.0.12r1041")
      Vagrant::Env.check_virtualbox!
    end

    should "error and exit if the the vboxconfig is not set" do
      VirtualBox::Global.expects(:vboxconfig?).returns(false)
      Vagrant::Env.expects(:error_and_exit).once
      Vagrant::Env.check_virtualbox!
    end
  end

  context "requiring a VM" do
    setup do
      Vagrant::Env.stubs(:require_root_path)
      Vagrant::Env.stubs(:error_and_exit)
    end

    should "require root path" do
      Vagrant::Env.expects(:require_root_path).once
      Vagrant::Env.require_persisted_vm
    end

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

    should "load from the home directory" do
      File.expects(:exist?).with(File.join(Vagrant::Env.home_path, Vagrant::Env::ROOTFILE_NAME)).once
      Vagrant::Env.load_config!
    end

    should "not load from the home directory if the home config is nil" do
      mock_config do |config|
        config.vagrant.home = nil
      end

      File.expects(:exist?).with(File.join(Vagrant::Env.home_path, Vagrant::Env::ROOTFILE_NAME)).never
      Vagrant::Env.load_config!
    end

    should "not load from the root path if nil" do
      Vagrant::Env.stubs(:root_path).returns(nil)
      File.expects(:exist?).with(File.join(@root_path, Vagrant::Env::ROOTFILE_NAME)).never
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
    should "load! should load the config and set the persisted_uid" do
      call_seq = sequence("call_sequence")
      Vagrant::Env.expects(:load_root_path!).once.in_sequence(call_seq)
      Vagrant::Env.expects(:load_config!).once.in_sequence(call_seq)
      Vagrant::Env.expects(:load_home_directory!).once.in_sequence(call_seq)
      Vagrant::Env.expects(:load_box!).once.in_sequence(call_seq)
      Vagrant::Env.expects(:load_config!).once.in_sequence(call_seq)
      Vagrant::Env.expects(:check_virtualbox!).once.in_sequence(call_seq)
      Vagrant::Env.expects(:load_vm!).once.in_sequence(call_seq)
      Vagrant::Env.load!
    end
  end

  context "persisting the VM into a file" do
    setup do
      @vm = mock("vm")
      @vm.stubs(:uuid).returns("foo")

      File.stubs(:open)
      Vagrant::ActiveList.stubs(:add)
    end

    should "should save it to the dotfile path" do
      filemock = mock("filemock")
      filemock.expects(:write).with(@vm.uuid)
      File.expects(:open).with(Vagrant::Env.dotfile_path, 'w+').once.yields(filemock)
      Vagrant::Env.persist_vm(@vm)
    end

    should "add the VM to the activelist" do
      Vagrant::ActiveList.expects(:add).with(@vm)
      Vagrant::Env.persist_vm(@vm)
    end
  end

  context "depersisting the VM" do
    setup do
      File.stubs(:exist?).returns(false)
      File.stubs(:delete)

      Vagrant::ActiveList.stubs(:remove)

      @dotfile_path = "foo"
      Vagrant::Env.stubs(:dotfile_path).returns(@dotfile_path)

      @vm = mock("vm")
    end

    should "remove the dotfile if it exists" do
      File.expects(:exist?).with(Vagrant::Env.dotfile_path).returns(true)
      File.expects(:delete).with(Vagrant::Env.dotfile_path).once
      Vagrant::Env.depersist_vm(@vm)
    end

    should "not remove the dotfile if it doesn't exist" do
      File.expects(:exist?).returns(false)
      File.expects(:delete).never
      Vagrant::Env.depersist_vm(@vm)
    end

    should "remove from the active list" do
      Vagrant::ActiveList.expects(:remove).with(@vm)
      Vagrant::Env.depersist_vm(@vm)
    end
  end

  context "loading the UUID out from the persisted file" do
    setup do
      File.stubs(:file?).returns(true)
    end

    should "loading of the uuid from the dotfile" do
      mock_persisted_vm
      assert_equal 'foovm', Vagrant::Env.persisted_vm
    end

    should "do nothing if the root path is nil" do
      File.expects(:open).never
      Vagrant::Env.stubs(:root_path).returns(nil)
      Vagrant::Env.load_vm!
    end

    should "do nothing if dotfile is not a file" do
      File.expects(:file?).returns(false)
      File.expects(:open).never
      Vagrant::Env.load_vm!
    end

    should "uuid should be nil if dotfile didn't exist" do
      File.expects(:open).raises(Errno::ENOENT)
      Vagrant::Env.load_vm!
      assert_nil Vagrant::Env.persisted_vm
    end

    should "should build up the dotfile out of the root path and the dotfile name" do
      assert_equal File.join(Vagrant::Env.root_path, Vagrant.config.vagrant.dotfile_name), Vagrant::Env.dotfile_path
    end
  end

  context "loading the root path" do
    should "default the path to the pwd if nil" do
      @path = mock("path")
      @path.stubs(:root?).returns(true)
      Pathname.expects(:new).with(Dir.pwd).returns(@path)
      Vagrant::Env.load_root_path!(nil)
    end

    should "not default the path to pwd if its not nil" do
      @path = mock("path")
      @path.stubs(:to_s).returns("/")
      File.expects(:expand_path).with(@path).returns("/")
      Pathname.expects(:new).with("/").returns(@path)
      @path.stubs(:root?).returns(true)
      Vagrant::Env.load_root_path!(@path)
    end

    should "should walk the parent directories looking for rootfile" do
      paths = [
        Pathname.new("/foo/bar/baz"),
        Pathname.new("/foo/bar"),
        Pathname.new("/foo")
      ]

      search_seq = sequence("search_seq")
      paths.each do |path|
        File.expects(:exist?).with("#{path}/#{Vagrant::Env::ROOTFILE_NAME}").returns(false).in_sequence(search_seq)
      end

      assert !Vagrant::Env.load_root_path!(paths.first)
    end

    should "return false if not found" do
      path = Pathname.new("/")
      assert !Vagrant::Env.load_root_path!(path)
    end

    should "return false if not found on windows-style root" do
      # TODO: Is there _any_ way to test this on unix machines? The
      # expand path doesn't work [properly for the test] on unix machines.
      if RUBY_PLATFORM.downcase.include?("mswin")
        # Note the escaped back slash
        path = Pathname.new("C:\\")
        assert !Vagrant::Env.load_root_path!(path)
      end
    end

    should "should set the path for the rootfile" do
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
      Vagrant::Env.stubs(:root_path).returns("foo")
    end

    should "do nothing if the root path is nil" do
      Vagrant::Box.expects(:find).never
      Vagrant::Env.stubs(:root_path).returns(nil)
      Vagrant::Env.load_vm!
    end

    should "not load the box if its not set" do
      mock_config do |config|
        config.vm.box = nil
      end

      Vagrant::Box.expects(:find).never
      Vagrant::Env.load_box!
    end

    should "set the box to what is found by the Box class" do
      Vagrant::Box.expects(:find).with(Vagrant.config.vm.box).once.returns(@box)
      Vagrant::Env.load_box!
      assert @box.equal?(Vagrant::Env.box)
    end
  end

  context "requiring boxes" do
    setup do
      Vagrant::Env.stubs(:require_root_path)
      Vagrant::Env.stubs(:error_and_exit)
    end

    should "require root path" do
      Vagrant::Env.expects(:require_root_path).once
      Vagrant::Env.require_box
    end

    should "error and exit if no box is specified" do
      mock_config do |config|
        config.vm.box = nil
      end

      Vagrant::Env.expects(:box).returns(nil)
      Vagrant::Env.expects(:error_and_exit).once.with(:box_not_specified)
      Vagrant::Env.require_box
    end

    should "error and exit if box is specified but doesn't exist" do
      mock_config do |config|
        config.vm.box = "foo"
      end

      Vagrant::Env.expects(:box).returns(nil)
      Vagrant::Env.expects(:error_and_exit).once.with(:box_specified_doesnt_exist, :box_name => "foo")
      Vagrant::Env.require_box
    end
  end

  context "requiring root_path" do
    should "error and exit if no root_path is set" do
      Vagrant::Env.expects(:root_path).returns(nil)
      Vagrant::Env.expects(:error_and_exit).once
      Vagrant::Env.require_root_path
    end

    should "not error and exit if root_path is set" do
      Vagrant::Env.expects(:root_path).returns("foo")
      Vagrant::Env.expects(:error_and_exit).never
      Vagrant::Env.require_root_path
    end
  end
end
