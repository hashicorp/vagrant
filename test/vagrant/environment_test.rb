require "test_helper"

class EnvironmentTest < Test::Unit::TestCase
  context "class method check virtualbox version" do
    setup do
      VirtualBox.stubs(:version).returns("3.1.4")
    end

    should "not error and exit if everything is good" do
      VirtualBox.expects(:version).returns("3.2.4")
      Vagrant::Environment.expects(:error_and_exit).never
      Vagrant::Environment.check_virtualbox!
    end

    should "error and exit if VirtualBox is not installed or detected" do
      Vagrant::Environment.expects(:error_and_exit).with(:virtualbox_not_detected).once
      VirtualBox.expects(:version).returns(nil)
      Vagrant::Environment.check_virtualbox!
    end

    should "error and exit if VirtualBox is lower than version 3.2" do
      version = "3.1.12r1041"
      Vagrant::Environment.expects(:error_and_exit).with(:virtualbox_invalid_version, :version => version.to_s).once
      VirtualBox.expects(:version).returns(version)
      Vagrant::Environment.check_virtualbox!
    end

    should "error and exit for OSE VirtualBox" do
      version = "3.2.6_OSE"
      Vagrant::Environment.expects(:error_and_exit).with(:virtualbox_invalid_ose, :version => version.to_s).once
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
      Vagrant::Environment.expects(:new).with(:cwd => @cwd).once.returns(@env)
      @env.expects(:load!).returns(@env)
      assert_equal @env, Vagrant::Environment.load!(@cwd)
    end

    should "work without a given cwd" do
      Vagrant::Environment.expects(:new).with(:cwd => nil).returns(@env)

      assert_nothing_raised {
        env = Vagrant::Environment.load!
        assert_equal env, @env
      }
    end
  end

  context "initialization" do
    should "set the cwd if given" do
      cwd = "foobarbaz"
      env = Vagrant::Environment.new(:cwd => cwd)
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

  context "loading" do
    setup do
      @env = mock_environment
    end

    context "overall load method" do
      should "load! should call proper sequence and return itself" do
        call_seq = sequence("call_sequence")
        @env.expects(:load_logger!).once.in_sequence(call_seq)
        @env.expects(:load_root_path!).once.in_sequence(call_seq)
        @env.expects(:load_config!).once.in_sequence(call_seq)
        @env.expects(:load_home_directory!).once.in_sequence(call_seq)
        @env.expects(:load_host!).once.in_sequence(call_seq)
        @env.expects(:load_box!).once.in_sequence(call_seq)
        @env.expects(:load_config!).once.in_sequence(call_seq)
        Vagrant::Environment.expects(:check_virtualbox!).once.in_sequence(call_seq)
        @env.expects(:load_vm!).once.in_sequence(call_seq)
        @env.expects(:load_active_list!).once.in_sequence(call_seq)
        @env.expects(:load_commands!).once.in_sequence(call_seq)
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
        @env.stubs(:load_logger!)

        @parent_env = mock_environment

        File.stubs(:exist?).returns(false)
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
        @env.expects(:load_logger!).once.in_sequence(load_seq)
        @env.load_config!
      end
    end

    context "loading logger" do
      setup do
        @env = mock_environment
        @env.stubs(:vm_name).returns(nil)
      end

      should "use 'vagrant' by default" do
        assert @env.vm_name.nil? # sanity
        @env.load_logger!
        assert_equal "vagrant", @env.logger.resource
      end

      should "use the vm name if available" do
        name = "foo"
        @env.stubs(:vm_name).returns(name)
        @env.load_logger!
        assert_equal name, @env.logger.resource
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
        @env = mock_environment
        @env.stubs(:root_path).returns("foo")

        File.stubs(:file?).returns(true)
      end

      should "blank the VMs" do
        load_seq = sequence("load_seq")
        @env.stubs(:root_path).returns("foo")
        @env.expects(:load_blank_vms!).in_sequence(load_seq)
        File.expects(:open).in_sequence(load_seq)
        @env.load_vm!
      end

      should "load the UUID if the JSON parsing fails" do
        vm = mock("vm")

        filemock = mock("filemock")
        filemock.expects(:read).returns("foo")
        Vagrant::VM.expects(:find).with("foo", @env, Vagrant::Environment::DEFAULT_VM).returns(vm)
        File.expects(:open).with(@env.dotfile_path).once.yields(filemock)
        File.expects(:file?).with(@env.dotfile_path).once.returns(true)
        @env.load_vm!

        assert_equal vm,  @env.vms.values.first
      end

      should "load all the VMs from the dotfile" do
        vms = { :foo => "bar", :bar => "baz" }
        results = {}

        filemock = mock("filemock")
        filemock.expects(:read).returns(vms.to_json)
        File.expects(:open).with(@env.dotfile_path).once.yields(filemock)
        File.expects(:file?).with(@env.dotfile_path).once.returns(true)

        vms.each do |key, value|
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

      should "do nothing if the dotfile is nil" do
        @env.stubs(:dotfile_path).returns(nil)
        File.expects(:open).never

        assert_nothing_raised {
          @env.load_vm!
        }
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

    context "loading blank VMs" do
      setup do
        @env = mock_environment
      end

      should "blank the VMs" do
        @env = mock_environment do |config|
          config.vm.define :foo do |config|
          end

          config.vm.define :bar do |config|
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

  context "requiring properties" do
    setup do
      @env = mock_environment
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
  end

  context "updating the dotfile" do
    setup do
      @env = mock_environment
      @env.stubs(:parent).returns(nil)
      @env.stubs(:dotfile_path).returns("foo")
      File.stubs(:open)
      File.stubs(:exist?).returns(true)
    end

    def create_vm(created)
      vm = mock("vm")
      vm.stubs(:created?).returns(created)
      vm.stubs(:uuid).returns("foo")
      vm
    end

    should "call parent if exists" do
      parent = mock("parent")
      @env.stubs(:parent).returns(parent)
      parent.expects(:update_dotfile).once

      @env.update_dotfile
    end

    should "remove the dotfile if the data is empty" do
      vms = {
        :foo => create_vm(false)
      }

      @env.stubs(:vms).returns(vms)
      File.expects(:delete).with(@env.dotfile_path).once
      @env.update_dotfile
    end

    should "not remove the dotfile if it doesn't exist" do
      vms = {
        :foo => create_vm(false)
      }

      @env.stubs(:vms).returns(vms)
      File.expects(:exist?).with(@env.dotfile_path).returns(false)
      File.expects(:delete).never
      assert_nothing_raised { @env.update_dotfile }
    end

    should "write the proper data to dotfile" do
      vms = {
        :foo => create_vm(false),
        :bar => create_vm(true),
        :baz => create_vm(true)
      }

      f = mock("f")
      @env.stubs(:vms).returns(vms)
      File.expects(:open).with(@env.dotfile_path, 'w+').yields(f)
      f.expects(:write).with() do |json|
        assert_nothing_raised {
          data = JSON.parse(json)
          assert_equal 2, data.length
          assert_equal vms[:bar].uuid, data["bar"]
          assert_equal vms[:baz].uuid, data["baz"]
        }

        true
      end

      @env.update_dotfile
    end
  end
end
