require File.join(File.dirname(__FILE__), '..', 'test_helper')

class EnvironmentTest < Test::Unit::TestCase
  context "class method check virtualbox version" do
    setup do
      VirtualBox.stubs(:version).returns("3.1.4")
    end

    should "not error and exit if everything is good" do
      VirtualBox.expects(:version).returns("3.1.4")
      Vagrant::Environment.expects(:error_and_exit).never
      Vagrant::Environment.check_virtualbox!
    end

    should "error and exit if VirtualBox is not installed or detected" do
      Vagrant::Environment.expects(:error_and_exit).with(:virtualbox_not_detected).once
      VirtualBox.expects(:version).returns(nil)
      Vagrant::Environment.check_virtualbox!
    end

    should "error and exit if VirtualBox is lower than version 3.1" do
      version = "3.0.12r1041"
      Vagrant::Environment.expects(:error_and_exit).with(:virtualbox_invalid_version, :version => version.to_s).once
      VirtualBox.expects(:version).returns(version)
      Vagrant::Environment.check_virtualbox!
    end
  end

  context "class method load!" do
    setup do
      @cwd = mock('cwd')

      @env = mock('env')
      @env.stubs(:load!).returns(@env)
    end

    should "create the environment with given cwd, load it, and return it" do
      Vagrant::Environment.expects(:new).with(@cwd).once.returns(@env)
      @env.expects(:load!).returns(@env)
      assert_equal @env, Vagrant::Environment.load!(@cwd)
    end

    should "work without a given cwd" do
      Vagrant::Environment.expects(:new).with(nil).returns(@env)

      assert_nothing_raised {
        env = Vagrant::Environment.load!
        assert_equal env, @env
      }
    end
  end

  context "initialization" do
    should "set the cwd if given" do
      cwd = "foobarbaz"
      env = Vagrant::Environment.new(cwd)
      assert_equal cwd, env.cwd
    end

    should "default to pwd if cwd is nil" do
      env = Vagrant::Environment.new
      assert_equal Dir.pwd, env.cwd
    end
  end

  context "paths" do
    setup do
      @env = mock_environment
    end

    context "cwd" do
      should "default to Dir.pwd" do
        assert_equal Dir.pwd, @env.cwd
      end

      should "return cwd if set" do
        @env.cwd = "foo"
        assert_equal "foo", @env.cwd
      end
    end

    context "dotfile path" do
      setup do
        @env.stubs(:root_path).returns("foo")
      end

      should "build up the dotfile out of the root path and the dotfile name" do
        assert_equal File.join(@env.root_path, @env.config.vagrant.dotfile_name), @env.dotfile_path
      end
    end

    context "home path" do
      should "return nil if config is not yet loaded" do
        @env.stubs(:config).returns(nil)
        assert_nil @env.home_path
      end

      should "return the home path if it loaded" do
        assert_equal @env.config.vagrant.home, @env.home_path
      end
    end

    context "temp path" do
      should "return the home path joined with 'tmp'" do
        home_path = "foo"
        @env.stubs(:home_path).returns(home_path)
        assert_equal File.join("foo", "tmp"), @env.tmp_path
      end
    end

    context "boxes path" do
      should "return the home path joined with 'tmp'" do
        home_path = "foo"
        @env.stubs(:home_path).returns(home_path)
        assert_equal File.join("foo", "boxes"), @env.boxes_path
      end
    end
  end

  context "loading" do
    setup do
      @env = mock_environment
    end

    context "overall load method" do
      should "load! should call proper sequence and return itself" do
        call_seq = sequence("call_sequence")
        @env.expects(:load_root_path!).once.in_sequence(call_seq)
        @env.expects(:load_config!).once.in_sequence(call_seq)
        @env.expects(:load_home_directory!).once.in_sequence(call_seq)
        @env.expects(:load_box!).once.in_sequence(call_seq)
        @env.expects(:load_config!).once.in_sequence(call_seq)
        Vagrant::Environment.expects(:check_virtualbox!).once.in_sequence(call_seq)
        @env.expects(:load_vm!).once.in_sequence(call_seq)
        @env.expects(:load_ssh!).once.in_sequence(call_seq)
        @env.expects(:load_active_list!).once.in_sequence(call_seq)
        @env.expects(:load_commands!).once.in_sequence(call_seq)
        assert_equal @env, @env.load!
      end
    end

    context "loading the root path" do
      setup do
        @env.cwd = "/foo"
      end

      should "default the path to the cwd instance var if nil" do
        @path = mock("path")
        @path.stubs(:root?).returns(true)
        File.expects(:expand_path).with(@env.cwd).returns(@env.cwd)
        Pathname.expects(:new).with(@env.cwd).returns(@path)
        @env.load_root_path!(nil)
      end

      should "not default the path to pwd if its not nil" do
        @path = mock("path")
        @path.stubs(:to_s).returns("/")
        File.expects(:expand_path).with(@path).returns("/")
        Pathname.expects(:new).with("/").returns(@path)
        @path.stubs(:root?).returns(true)
        @env.load_root_path!(@path)
      end

      should "should walk the parent directories looking for rootfile" do
        paths = [
          Pathname.new("/foo/bar/baz"),
          Pathname.new("/foo/bar"),
          Pathname.new("/foo")
        ]

        search_seq = sequence("search_seq")
        paths.each do |path|
          # NOTE File.expect(:expand_path) causes tests to hang in windows below is the interim solution
          File.expects(:exist?).with("#{File.expand_path(path)}/#{Vagrant::Environment::ROOTFILE_NAME}").returns(false).in_sequence(search_seq)
        end

        assert !@env.load_root_path!(paths.first)
      end

      should "return false if not found" do
        path = Pathname.new("/")
        assert !@env.load_root_path!(path)
      end

      should "return false if not found on windows-style root" do
        # TODO: Is there _any_ way to test this on unix machines? The
        # expand path doesn't work [properly for the test] on unix machines.
        if RUBY_PLATFORM.downcase.include?("mswin")
          # Note the escaped back slash
          path = Pathname.new("C:\\")
          assert !@env.load_root_path!(path)
        end
      end

      should "should set the path for the rootfile" do
        # NOTE File.expect(:expand_path) causes tests to hang in windows below is the interim solution
        path = File.expand_path("/foo")
        File.expects(:exist?).with("#{path}/#{Vagrant::Environment::ROOTFILE_NAME}").returns(true)

        assert @env.load_root_path!(Pathname.new(path))
        assert_equal path, @env.root_path
      end
    end

    context "loading config" do
      setup do
        @root_path = "/foo"
        @home_path = "/bar"
        @env.stubs(:root_path).returns(@root_path)
        @env.stubs(:home_path).returns(@home_path)

        File.stubs(:exist?).returns(false)
        Vagrant::Config.stubs(:execute!)
        Vagrant::Config.stubs(:reset!)
      end

      should "reset the configuration object" do
        Vagrant::Config.expects(:reset!).with(@env).once
        @env.load_config!
      end

      should "load from the project root" do
        File.expects(:exist?).with(File.join(PROJECT_ROOT, "config", "default.rb")).once
        @env.load_config!
      end

      should "load from the root path" do
        File.expects(:exist?).with(File.join(@root_path, Vagrant::Environment::ROOTFILE_NAME)).once
        @env.load_config!
      end

      should "not load from the root path if nil" do
        @env.stubs(:root_path).returns(nil)
        File.expects(:exist?).with(File.join(@root_path, Vagrant::Environment::ROOTFILE_NAME)).never
        @env.load_config!
      end

      should "load from the home directory" do
        File.expects(:exist?).with(File.join(@env.home_path, Vagrant::Environment::ROOTFILE_NAME)).once
        @env.load_config!
      end

      should "not load from the home directory if the config is nil" do
        @env.stubs(:home_path).returns(nil)
        File.expects(:exist?).twice.returns(false)
        @env.load_config!
      end

      should "not load from the box directory if it is nil" do
        @env.expects(:box).once.returns(nil)
        File.expects(:exist?).twice.returns(false)
        @env.load_config!
      end

      should "load from the box directory if it is not nil" do
        dir = "foo"
        box = mock("box")
        box.stubs(:directory).returns(dir)
        @env.expects(:box).twice.returns(box)
        File.expects(:exist?).with(File.join(dir, Vagrant::Environment::ROOTFILE_NAME)).once
        @env.load_config!
      end

      should "load the files only if exist? returns true" do
        File.expects(:exist?).once.returns(true)
        @env.expects(:load).once
        @env.load_config!
      end

      should "not load the files if exist? returns false" do
        @env.expects(:load).never
        @env.load_config!
      end

      should "execute after loading and set result to environment config" do
        result = mock("result")
        File.expects(:exist?).once.returns(true)
        @env.expects(:load).once
        Vagrant::Config.expects(:execute!).once.returns(result)
        @env.load_config!
        assert_equal result, @env.config
      end
    end

    context "loading home directory" do
      setup do
        @env = mock_environment
        @home_dir = File.expand_path(@env.config.vagrant.home)

        File.stubs(:directory?).returns(true)
        FileUtils.stubs(:mkdir_p)
      end

      should "create each directory if it doesn't exist" do
        create_seq = sequence("create_seq")
        File.stubs(:directory?).returns(false)
        Vagrant::Environment::HOME_SUBDIRS.each do |subdir|
          FileUtils.expects(:mkdir_p).with(File.join(@home_dir, subdir)).in_sequence(create_seq)
        end

        @env.load_home_directory!
      end

      should "not create directories if they exist" do
        File.stubs(:directory?).returns(true)
        FileUtils.expects(:mkdir_p).never
        @env.load_home_directory!
      end
    end

    context "loading box" do
      setup do
        @box = mock("box")
        @box.stubs(:env=)

        @env = mock_environment
        @env.stubs(:root_path).returns("foo")
      end

      should "do nothing if the root path is nil" do
        Vagrant::Box.expects(:find).never
        @env.stubs(:root_path).returns(nil)
        @env.load_box!
      end

      should "not load the box if its not set" do
        @env = mock_environment do |config|
          config.vm.box = nil
        end

        Vagrant::Box.expects(:find).never
        @env.load_box!
      end

      should "set the box to what is found by the Box class" do
        Vagrant::Box.expects(:find).with(@env, @env.config.vm.box).once.returns(@box)
        @env.load_box!
        assert @box.equal?(@env.box)
      end
    end

    context "loading the UUID out from the persisted dotfile" do
      setup do
        @env = mock_environment
        @env.stubs(:root_path).returns("foo")

        File.stubs(:file?).returns(true)
      end

      should "loading of the uuid from the dotfile" do
        vm = mock("vm")
        vm.expects(:env=).with(@env)

        filemock = mock("filemock")
        filemock.expects(:read).returns("foo")
        Vagrant::VM.expects(:find).with("foo").returns(vm)
        File.expects(:open).with(@env.dotfile_path).once.yields(filemock)
        File.expects(:file?).with(@env.dotfile_path).once.returns(true)
        @env.load_vm!

        assert_equal vm, @env.vm
      end

      should "not set the environment if the VM is nil" do
        filemock = mock("filemock")
        filemock.expects(:read).returns("foo")
        Vagrant::VM.expects(:find).with("foo").returns(nil)
        File.expects(:open).with(@env.dotfile_path).once.yields(filemock)
        File.expects(:file?).with(@env.dotfile_path).once.returns(true)

        assert_nothing_raised { @env.load_vm! }
        assert_nil @env.vm
      end

      should "do nothing if the root path is nil" do
        File.expects(:open).never
        @env.stubs(:root_path).returns(nil)
        @env.load_vm!
      end

      should "do nothing if dotfile is not a file" do
        File.expects(:file?).returns(false)
        File.expects(:open).never
        @env.load_vm!
      end

      should "uuid should be nil if dotfile didn't exist" do
        File.expects(:open).raises(Errno::ENOENT)
        @env.load_vm!
        assert_nil @env.vm
      end
    end

    context "loading SSH" do
      setup do
        @env = mock_environment
      end

      should "initialize the SSH object with the given environment" do
        ssh = mock("ssh")
        Vagrant::SSH.expects(:new).with(@env).returns(ssh)
        @env.load_ssh!
        assert_equal ssh, @env.ssh
      end
    end

    context "loading the active list" do
      setup do
        @env = mock_environment
      end

      should "initialize the ActiveList object with the given environment" do
        active_list = mock("active_list")
        Vagrant::ActiveList.expects(:new).with(@env).returns(active_list)
        @env.load_active_list!
        assert_equal active_list, @env.active_list
      end
    end

    context "loading the commands" do
      setup do
        @env = mock_environment
      end

      should "initialize the Commands object with the given environment" do
        commands = mock("commands")
        Vagrant::Command.expects(:new).with(@env).returns(commands)
        @env.load_commands!
        assert_equal commands, @env.commands
      end
    end
  end

  context "requiring properties" do
    setup do
      @env = mock_environment
    end

    context "requiring boxes" do
      setup do
        reconfig_environment
      end

      def reconfig_environment
        @env = mock_environment do |config|
          yield config if block_given?
        end

        @env.stubs(:require_root_path)
        @env.stubs(:error_and_exit)
      end

      should "require root path" do
        @env.expects(:require_root_path).once
        @env.require_box
      end

      should "error and exit if no box is specified" do
        reconfig_environment do |config|
          config.vm.box = nil
        end

        @env.expects(:box).returns(nil)
        @env.expects(:error_and_exit).once.with(:box_not_specified)
        @env.require_box
      end

      should "error and exit if box is specified but doesn't exist" do
        reconfig_environment do |config|
          config.vm.box = "foo"
        end

        @env.expects(:box).returns(nil)
        @env.expects(:error_and_exit).once.with(:box_specified_doesnt_exist, :box_name => "foo")
        @env.require_box
      end
    end

    context "requiring root_path" do
      should "error and exit if no root_path is set" do
        @env.expects(:root_path).returns(nil)
        @env.expects(:error_and_exit).with(:rootfile_not_found).once
        @env.require_root_path
      end

      should "not error and exit if root_path is set" do
        @env.expects(:root_path).returns("foo")
        @env.expects(:error_and_exit).never
        @env.require_root_path
      end
    end

    context "requiring a persisted VM" do
      setup do
        @env.stubs(:vm).returns("foo")
        @env.stubs(:require_root_path)
      end

      should "require a root path" do
        @env.expects(:require_root_path).once
        @env.expects(:error_and_exit).never
        @env.require_persisted_vm
      end

      should "error and exit if the VM is not set" do
        @env.expects(:vm).returns(nil)
        @env.expects(:error_and_exit).once
        @env.require_persisted_vm
      end
    end
  end

  context "managing VM" do
    setup do
      @env = mock_environment

      @dotfile_path = "foo"
      @env.stubs(:dotfile_path).returns(@dotfile_path)
    end

    def mock_vm
      @vm = mock("vm")
      @vm.stubs(:uuid).returns("foo")
      @env.stubs(:vm).returns(@vm)
    end

    context "creating a new VM" do
      should "create a new VM" do
        assert_nil @env.vm
        @env.create_vm
        assert !@env.vm.nil?
        assert @env.vm.is_a?(Vagrant::VM)
      end

      should "set the new VM's environment to the env" do
        @env.create_vm
        assert_equal @env, @env.vm.env
      end

      should "return the new VM" do
        result = @env.create_vm
        assert result.is_a?(Vagrant::VM)
      end
    end

    context "persisting the VM into a file" do
      setup do
        mock_vm

        File.stubs(:open)
        @env.active_list.stubs(:add)
      end

      should "should save it to the dotfile path" do
        filemock = mock("filemock")
        filemock.expects(:write).with(@vm.uuid)
        File.expects(:open).with(@env.dotfile_path, 'w+').once.yields(filemock)
        @env.persist_vm
      end

      should "add the VM to the activelist" do
        @env.active_list.expects(:add).with(@vm)
        @env.persist_vm
      end
    end

    context "depersisting the VM" do
      setup do
        mock_vm

        File.stubs(:exist?).returns(false)
        File.stubs(:delete)

        @env.active_list.stubs(:remove)
      end

      should "remove the dotfile if it exists" do
        File.expects(:exist?).with(@env.dotfile_path).returns(true)
        File.expects(:delete).with(@env.dotfile_path).once
        @env.depersist_vm
      end

      should "not remove the dotfile if it doesn't exist" do
        File.expects(:exist?).returns(false)
        File.expects(:delete).never
        @env.depersist_vm
      end

      should "remove from the active list" do
        @env.active_list.expects(:remove).with(@vm)
        @env.depersist_vm
      end
    end
  end
end
