require "test_helper"
require "pathname"

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

  context "initialization" do
    should "set the cwd if given" do
      cwd = "foobarbaz"
      env = @klass.new(:cwd => cwd)
      assert_equal Pathname.new(cwd), env.cwd
    end

    should "default to pwd if cwd is nil" do
      env = @klass.new
      assert_equal Pathname.new(Dir.pwd), env.cwd
    end
  end

  context "paths" do
    setup do
      @env = vagrant_env
    end

    context "dotfile path" do
      should "build up the dotfile out of the root path and the dotfile name" do
        assert_equal @env.root_path.join(@env.config.vagrant.dotfile_name), @env.dotfile_path
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
        assert_equal File.join(@env.home_path, "tmp"), @env.tmp_path
      end
    end

    context "boxes path" do
      should "return the home path joined with 'tmp'" do
        assert_equal File.join(@env.home_path, "boxes"), @env.boxes_path
      end
    end
  end

  context "resource" do
    setup do
      @env = vagrant_env
    end

    should "return 'vagrant' as a default" do
      assert_equal 'vagrant', @env.resource
    end

    should "return the VM name if it is specified" do
      @env.stubs(:vm).returns(mock("vm", :name => "foo"))
      assert_equal "foo", @env.resource
    end
  end

  context "primary VM helper" do
    should "return the first VM if not multivm" do
      env = vagrant_env
      assert_equal env.vms[@klass::DEFAULT_VM], env.primary_vm
    end

    should "call and return the primary VM from the parent if has one" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define(:web, :primary => true) do; end
        config.vm.define :db do; end
      vf

      assert_equal :web, env.primary_vm.name
    end

    should "return nil if no VM is marked as primary" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
        config.vm.define :utility
      vf

      assert env.primary_vm.nil?
    end
  end

  context "multivm? helper" do
    should "return true if VM length greater than 1" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
      vf

      assert env.multivm?
    end

    should "return false if VM length is 1" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
      vf

      assert !env.multivm?
    end
  end

  context "local data" do
    should "lazy load the data store only once" do
      result = { :foo => :bar }
      Vagrant::DataStore.expects(:new).returns(result).once
      env = vagrant_env
      assert_equal result, env.local_data
      assert_equal result, env.local_data
      assert_equal result, env.local_data
    end

    should "return the parent's local data if a parent exists" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
      vf

      env.local_data[:foo] = :bar

      Vagrant::DataStore.expects(:new).never
      assert_equal :bar, env.vms[:web].env.local_data[:foo]
    end
  end

  context "accessing host" do
    should "load the host once" do
      env = @klass.new(:cwd => vagrant_app)
      result = mock("result")
      Vagrant::Hosts::Base.expects(:load).with(env, env.config.vagrant.host).once.returns(result)
      assert_equal result, env.host
      assert_equal result, env.host
      assert_equal result, env.host
    end
  end

  context "accessing actions" do
    should "initialize the Action object with the given environment" do
      env = @klass.new(:cwd => vagrant_app)
      result = mock("result")
      Vagrant::Action.expects(:new).with(env).returns(result).once
      assert_equal result, env.actions
      assert_equal result, env.actions
      assert_equal result, env.actions
    end
  end

  context "global data" do
    should "lazy load the data store only once" do
      env = vagrant_env
      store = env.global_data

      assert env.global_data.equal?(store)
      assert env.global_data.equal?(store)
      assert env.global_data.equal?(store)
    end

    should "return the parent's local data if a parent exists" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
      vf

      result = env.global_data

      Vagrant::DataStore.expects(:new).never
      assert env.vms[:web].env.global_data.equal?(result)
    end
  end

  context "loading logger" do
    should "lazy load the logger only once" do
      result = Vagrant::Util::ResourceLogger.new("vagrant", mock_environment)
      Vagrant::Util::ResourceLogger.expects(:new).returns(result).once
      env = vagrant_env
      assert_equal result, env.logger
      assert_equal result, env.logger
      assert_equal result, env.logger
    end

    should "return the parent's logger if a parent exists" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
      vf

      result = env.logger

      Vagrant::Util::ResourceLogger.expects(:new).never
      assert env.vms[:web].env.logger.equal?(result)
    end
  end

  context "loading the root path" do
    should "should walk the parent directories looking for rootfile" do
      paths = [Pathname.new("/foo/bar/baz"),
               Pathname.new("/foo/bar"),
               Pathname.new("/foo"),
               Pathname.new("/")
              ]

      search_seq = sequence("search_seq")
      paths.each do |path|
        File.expects(:exist?).with(File.join(path.to_s, @klass::ROOTFILE_NAME)).returns(false).in_sequence(search_seq)
      end

      assert !@klass.new(:cwd => paths.first).root_path
    end

    should "should set the path for the rootfile" do
      path = File.expand_path("/foo")
      File.expects(:exist?).with(File.join(path, @klass::ROOTFILE_NAME)).returns(true)

      assert_equal Pathname.new(path), @klass.new(:cwd => path).root_path
    end

    should "only load the root path once" do
      env = @klass.new
      File.expects(:exist?).with(File.join(env.cwd, @klass::ROOTFILE_NAME)).returns(true).once

      assert_equal env.cwd, env.root_path
      assert_equal env.cwd, env.root_path
      assert_equal env.cwd, env.root_path
    end

    should "only load the root path once even if nil" do
      File.stubs(:exist?).returns(false)

      env = @klass.new
      assert env.root_path.nil?
      assert env.root_path.nil?
      assert env.root_path.nil?
    end
  end

  context "accessing the configuration" do
    should "load the environment if its not already loaded" do
      env = @klass.new(:cwd => vagrantfile)
      env.expects(:load!).once
      env.config
    end

    should "not load the environment if its already loaded" do
      env = vagrant_env
      env.expects(:load!).never
      env.config
    end
  end

  context "accessing the VMs hash" do
    should "load the environment if its not already loaded" do
      env = @klass.new(:cwd => vagrantfile)
      env.expects(:load!).once
      env.vms
    end

    should "not load the environment if its already loaded" do
      env = vagrant_env
      env.expects(:load!).never
      env.vms
    end

    should "return the parent's VMs hash if it has one" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
      vf

      assert env.vms[:web].env.vms.equal?(env.vms)
    end
  end

  context "loading" do
    setup do
      @env = mock_environment
    end

    context "overall load method" do
      should "load! should call proper sequence and return itself" do
        env = @klass.new(:cwd => vagrantfile)
        call_seq = sequence("call_sequence")
        @klass.expects(:check_virtualbox!).once.in_sequence(call_seq)
        env.expects(:load_config!).once.in_sequence(call_seq)
        env.expects(:load_vm!).once.in_sequence(call_seq)
        env.actions.expects(:run).with(:environment_load).once.in_sequence(call_seq)
        assert_equal env, env.load!
      end
    end

    context "loading config" do
      setup do
        @root_path = "/foo"
        @home_path = "/bar"
        @env.stubs(:root_path).returns(@root_path)
        @env.stubs(:home_path).returns(@home_path)

        # Temporary
        @env.stubs(:load_home_directory!)
        @env.stubs(:load_box!)

        @loader = Vagrant::Config.new(@env)
        Vagrant::Config.stubs(:new).returns(@loader)
        @loader.stubs(:load!)
      end

      should "load from the project root" do
        @env.load_config!
        assert @loader.queue.include?(File.expand_path("config/default.rb", Vagrant.source_root))
      end

      should "load from the root path" do
        @env.load_config!
        assert @loader.queue.include?(File.join(@root_path, @klass::ROOTFILE_NAME))
      end

      should "not load from the root path if nil" do
        @env.stubs(:root_path).returns(nil)
        @env.load_config!
        assert !@loader.queue.include?(File.join(@root_path, @klass::ROOTFILE_NAME))
      end

      should "load from the home directory" do
        @env.load_config!
        assert @loader.queue.include?(File.join(@env.home_path, @klass::ROOTFILE_NAME))
      end

      should "not load from the home directory if the config is nil" do
        @env.stubs(:home_path).returns(nil)
        @env.load_config!
        assert !@loader.queue.include?(File.join(@home_path, @klass::ROOTFILE_NAME))
      end

      should "load from the box directory if it is not nil" do
        dir = "foo"
        box = mock("box")
        box.stubs(:directory).returns(dir)
        @env.expects(:box).twice.returns(box)
        @env.load_config!
        assert @loader.queue.include?(File.join(dir, @klass::ROOTFILE_NAME))
      end

      should "load a sub-VM configuration if specified" do
        vm_name = :foobar
        proc = Proc.new {}
        parent_env = mock_environment
        parent_env.config.vm.define(vm_name, &proc)
        @env.stubs(:parent).returns(parent_env)
        @env.stubs(:vm).returns(mock("vm", :name => vm_name))

        @env.load_config!
        assert @loader.queue.flatten.include?(proc)
      end

      should "execute after loading and set result to environment config" do
        result = mock("result")
        @loader.stubs(:load!).returns(result)
        @env.load_config!
        assert_equal result, @env.config
      end

      should "reload the logger after executing" do
        @env.load_config!
        assert @env.instance_variable_get(:@logger).nil?
      end
    end

    context "loading home directory" do
      setup do
        @env = vagrant_env
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

    context "loading box" do
      should "do nothing if the root path is nil" do
        env = @klass.new(:cwd => "/")
        Vagrant::Box.expects(:find).never
        env.load_box!
      end

      should "not load the box if its not set" do
        env = vagrant_env
        assert env.config.vm.box.nil?
        Vagrant::Box.expects(:find).never
        env.load_box!
      end

      should "set the box to what is found by the Box class" do
        env = vagrant_env(vagrantfile("config.vm.box = 'foo'"))

        @box = mock("box")
        @box.stubs(:env=)
        Vagrant::Box.expects(:find).with(env, env.config.vm.box).once.returns(@box)
        env.load_box!
        assert @box.equal?(env.box)
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

      should "do nothing if the parent is set" do
        env = vagrant_env(vagrantfile(<<-vf))
          config.vm.define :web
          config.vm.define :db
        vf

        subenv = env.vms[:web].env
        subenv.expects(:load_blank_vms!).never
        subenv.load_vm!
      end

      should "uuid should be nil if local data contains nothing" do
        assert @local_data.empty? # sanity
        @env.load_vm!
        assert_nil @env.vm
      end
    end

    context "loading blank VMs" do
      should "blank the VMs" do
        env = vagrant_env(vagrantfile(<<-vf))
          config.vm.define :foo
          config.vm.define :bar
        vf

        env.load_blank_vms!

        assert_equal 2, env.vms.length
        assert(env.vms.all? { |name, vm| !vm.created? })

        sorted_vms = env.vms.keys.sort { |a,b| a.to_s <=> b.to_s }
        assert_equal [:bar, :foo], sorted_vms
      end

      should "load the default VM blank if no multi-VMs are specified" do
        env = vagrant_env
        assert env.config.vm.defined_vms.empty? # sanity

        env.load_blank_vms!

        assert_equal 1, env.vms.length
        assert !env.vms.values.first.created?
      end
    end
  end
end
