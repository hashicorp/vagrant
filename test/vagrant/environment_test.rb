require "test_helper"

class EnvironmentTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Environment
  end

  context "class method check virtualbox version" do
    setup do
      VirtualBox.stubs(:version).returns("3.1.4")
    end

    should "not error and exit if everything is good" do
      VirtualBox.expects(:version).returns("3.2.4")
      assert_nothing_raised { @klass.check_virtualbox! }
    end

    should "error and exit if VirtualBox is not installed or detected" do
      VirtualBox.expects(:version).returns(nil)
      assert_raises(Vagrant::Errors::VirtualBoxNotDetected) { @klass.check_virtualbox! }
    end

    should "error and exit if VirtualBox is lower than version 3.2" do
      version = "3.1.12r1041"
      VirtualBox.expects(:version).returns(version)
      assert_raises(Vagrant::Errors::VirtualBoxInvalidVersion) { @klass.check_virtualbox! }
    end

    should "error and exit for OSE VirtualBox" do
      version = "3.2.6_OSE"
      VirtualBox.expects(:version).returns(version)
      assert_raises(Vagrant::Errors::VirtualBoxInvalidOSE) { @klass.check_virtualbox! }
    end
  end

  context "class method load!" do
    setup do
      @cwd = mock('cwd')

      @env = mock('env')
      @env.stubs(:load!).returns(@env)
    end

    should "create the environment with given cwd, load it, and return it" do
      @klass.expects(:new).with(:cwd => @cwd).once.returns(@env)
      @env.expects(:load!).returns(@env)
      assert_equal @env, @klass.load!(@cwd)
    end

    should "work without a given cwd" do
      @klass.expects(:new).with(:cwd => nil).returns(@env)

      assert_nothing_raised {
        env = @klass.load!
        assert_equal env, @env
      }
    end
  end

  context "initialization" do
    should "set the cwd if given" do
      cwd = "foobarbaz"
      env = @klass.new(:cwd => cwd)
      assert_equal cwd, env.cwd
    end

    should "default to pwd if cwd is nil" do
      env = @klass.new
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

  context "resource" do
    setup do
      @env = mock_environment
    end

    should "return 'vagrant' as a default" do
      assert_equal 'vagrant', @env.resource
    end

    should "return the VM name if it is specified" do
      @env.stubs(:vm_name).returns("foo")
      assert_equal "foo", @env.resource
    end
  end

  context "primary VM helper" do
    setup do
      @env = mock_environment
      @env.stubs(:multivm?).returns(true)
    end

    should "return the first VM if not multivm" do
      result = mock("result")

      @env.stubs(:multivm?).returns(false)
      @env.stubs(:vms).returns({:default => result})

      assert_equal result, @env.primary_vm
    end

    should "call and return the primary VM from the parent if has one" do
      result = mock("result")
      parent = mock("parent")
      parent.expects(:primary_vm).returns(result)

      @env.stubs(:parent).returns(parent)
      assert_equal result, @env.primary_vm
    end

    should "return nil if no VM is marked as primary" do
      @env.config.vm.define(:foo)
      @env.config.vm.define(:bar)
      @env.config.vm.define(:baz)

      assert @env.primary_vm.nil?
    end

    should "return the primary VM" do
      @env.config.vm.define(:foo)
      @env.config.vm.define(:bar, :primary => true)
      @env.config.vm.define(:baz)

      result = mock("result")
      vms = {
        :foo => :foo,
        :bar => result,
        :baz => :baz
      }
      @env.stubs(:vms).returns(vms)

      assert_equal result, @env.primary_vm
    end
  end

  context "multivm? helper" do
    setup do
      @env = mock_environment
    end

    context "with a parent" do
      setup do
        @parent = mock('parent')
        @env.stubs(:parent).returns(@parent)
      end

      should "return the value of multivm? from the parent" do
        result = mock("result")
        @parent.stubs(:multivm?).returns(result)
        assert_equal result, @env.multivm?
      end
    end

    context "without a parent" do
      setup do
        @env.stubs(:parent).returns(nil)
      end

      should "return true if VM length greater than 1" do
        @env.stubs(:vms).returns([1,2,3])
        assert @env.multivm?
      end

      should "return false if VM length is 1" do
        @env.stubs(:vms).returns([1])
        assert !@env.multivm?
      end
    end
  end

  context "local data" do
    setup do
      @env = mock_environment
    end

    should "lazy load the data store only once" do
      result = mock("result")
      Vagrant::DataStore.expects(:new).with(@env.dotfile_path).returns(result).once
      assert_equal result, @env.local_data
      assert_equal result, @env.local_data
      assert_equal result, @env.local_data
    end

    should "return the parent's local data if a parent exists" do
      @env.stubs(:parent).returns(mock_environment)
      result = @env.parent.local_data

      Vagrant::DataStore.expects(:new).never
      assert_equal result, @env.local_data
    end
  end

  context "loading logger" do
    should "lazy load the logger only once" do
      result = Vagrant::Util::ResourceLogger.new("vagrant", mock_environment)
      Vagrant::Util::ResourceLogger.expects(:new).returns(result).once
      @env = mock_environment
      assert_equal result, @env.logger
      assert_equal result, @env.logger
      assert_equal result, @env.logger
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
        @env.expects(:load_host!).once.in_sequence(call_seq)
        @env.expects(:load_box!).once.in_sequence(call_seq)
        @env.expects(:load_config!).once.in_sequence(call_seq)
        @klass.expects(:check_virtualbox!).once.in_sequence(call_seq)
        @env.expects(:load_vm!).once.in_sequence(call_seq)
        @env.expects(:load_actions!).once.in_sequence(call_seq)
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
          File.expects(:exist?).with("#{File.expand_path(path)}/#{@klass::ROOTFILE_NAME}").returns(false).in_sequence(search_seq)
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
        File.expects(:exist?).with("#{path}/#{@klass::ROOTFILE_NAME}").returns(true)

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

        @parent_env = mock_environment

        File.stubs(:exist?).returns(false)
      end

      should "reset the configuration object" do
        Vagrant::Config.expects(:reset!).with(@env).once
        @env.load_config!
      end

      should "load from the project root" do
        File.expects(:exist?).with(File.join(Vagrant.source_root, "config", "default.rb")).once
        @env.load_config!
      end

      should "load from the root path" do
        File.expects(:exist?).with(File.join(@root_path, @klass::ROOTFILE_NAME)).once
        @env.load_config!
      end

      should "not load from the root path if nil" do
        @env.stubs(:root_path).returns(nil)
        File.expects(:exist?).with(File.join(@root_path, @klass::ROOTFILE_NAME)).never
        @env.load_config!
      end

      should "load from the home directory" do
        File.expects(:exist?).with(File.join(@env.home_path, @klass::ROOTFILE_NAME)).once
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
        File.expects(:exist?).with(File.join(dir, @klass::ROOTFILE_NAME)).once
        @env.load_config!
      end

      should "load a sub-VM configuration if specified" do
        vm_name = :foo
        sub_box = :YO
        @parent_env.config.vm.box = :NO
        @parent_env.config.vm.define(vm_name) do |config|
          config.vm.box = sub_box
        end

        # Sanity
        assert_equal :NO, @parent_env.config.vm.box

        @env.stubs(:vm_name).returns(vm_name)
        @env.stubs(:parent).returns(@parent_env)

        @env.load_config!

        assert_equal sub_box, @env.config.vm.box
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

      should "reload the logger after executing" do
        load_seq = sequence("load_seq")
        Vagrant::Config.expects(:execute!).once.returns(nil).in_sequence(load_seq)
        @env.load_config!
        assert @env.instance_variable_get(:@logger).nil?
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
        @klass::HOME_SUBDIRS.each do |subdir|
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

    context "loading host" do
      setup do
        @env = mock_environment
      end

      should "load the host by calling the load method on Host::Base" do
        result = mock("result")
        Vagrant::Hosts::Base.expects(:load).with(@env, @env.config.vagrant.host).once.returns(result)
        @env.load_host!
        assert_equal result, @env.host
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
        @local_data = {}

        @env = mock_environment
        @env.stubs(:root_path).returns("foo")
        @env.stubs(:local_data).returns(@local_data)
      end

      should "blank the VMs" do
        load_seq = sequence("load_seq")
        @env.stubs(:root_path).returns("foo")
        @env.expects(:load_blank_vms!).in_sequence(load_seq)
        @env.load_vm!
      end

      should "load all the VMs from the dotfile" do
        @local_data[:active] = { :foo => "bar", :bar => "baz" }

        results = {}
        @local_data[:active].each do |key, value|
          vm = mock("vm#{key}")
          Vagrant::VM.expects(:find).with(value, @env, key.to_sym).returns(vm)
          results[key] = vm
        end

        @env.load_vm!

        results.each do |key, value|
          assert_equal value, @env.vms[key]
        end
      end

      should "do nothing if the vm_name is set" do
        @env.stubs(:vm_name).returns(:foo)
        File.expects(:open).never
        @env.load_vm!
      end

      should "uuid should be nil if local data contains nothing" do
        assert @local_data.empty? # sanity
        @env.load_vm!
        assert_nil @env.vm
      end
    end

    context "loading blank VMs" do
      setup do
        @env = mock_environment
      end

      should "blank the VMs" do
        @env = mock_environment do |config|
          config.vm.define :foo do |foo_config|
          end

          config.vm.define :bar do |bar_config|
          end
        end

        @env.load_blank_vms!

        assert_equal 2, @env.vms.length
        assert(@env.vms.all? { |name, vm| !vm.created? })

        sorted_vms = @env.vms.keys.sort { |a,b| a.to_s <=> b.to_s }
        assert_equal [:bar, :foo], sorted_vms
      end

      should "load the default VM blank if no multi-VMs are specified" do
        assert @env.config.vm.defined_vms.empty? # sanity

        @env.load_blank_vms!

        assert_equal 1, @env.vms.length
        assert !@env.vms.values.first.created?
      end
    end

    context "loading actions" do
      setup do
        @env = mock_environment
      end

      should "initialize the Action object with the given environment" do
        result = mock("result")
        Vagrant::Action.expects(:new).with(@env).returns(result)
        @env.load_actions!
        assert_equal result, @env.actions
      end
    end
  end
end
