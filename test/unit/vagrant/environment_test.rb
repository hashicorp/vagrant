require "test_helper"
require "pathname"
require "tempfile"

class EnvironmentTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Environment

    clean_paths
  end

  context "class method check virtualbox version" do
    setup do
      VirtualBox.stubs(:version).returns("4.1.0")
    end

    should "not error and exit if everything is good" do
      VirtualBox.expects(:version).returns("4.1.0")
      assert_nothing_raised { @klass.check_virtualbox! }
    end

    should "error and exit if VirtualBox is not installed or detected" do
      VirtualBox.expects(:version).returns(nil)
      assert_raises(Vagrant::Errors::VirtualBoxNotDetected) { @klass.check_virtualbox! }
    end

    should "error and exit if VirtualBox is lower than version 4.0" do
      version = "3.2.12r1041"
      VirtualBox.expects(:version).returns(version)
      assert_raises(Vagrant::Errors::VirtualBoxInvalidVersion) { @klass.check_virtualbox! }
    end
  end

  context "class method argument parsing" do
    should "set the vagrantfile_name option" do
      env = @klass.parse(%w[--vagrantfile=/foo/bar])
      assert env.vagrantfile_name.include?('/foo/bar')

      env = @klass.parse(%w[--vagrantfile /foo/bar])
      assert env.vagrantfile_name.include?('/foo/bar')
    end

    should "set the cwd option" do
      env = @klass.parse(%w[--cwd=/foo/bar])
      assert_equal Pathname.new('/foo/bar'), env.cwd

      env = @klass.parse(%w[--cwd /foo/bar])
      assert_equal Pathname.new('/foo/bar'), env.cwd
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
      setup do
        @env = @klass.new

        # Make a fake home directory for helping with tests
        @home_path = tmp_path.join("home")
        ENV["HOME"] = @home_path.to_s
        FileUtils.rm_rf(@home_path)
        FileUtils.mkdir_p(@home_path)
      end

      should "return the home path if it loaded" do
        ENV["VAGRANT_HOME"] = nil

        expected = Pathname.new(File.expand_path(@klass::DEFAULT_HOME))
        assert_equal expected, @env.home_path
      end

      should "return the home path set by the environmental variable" do
        ENV["VAGRANT_HOME"] = "foo"

        expected = Pathname.new(File.expand_path(ENV["VAGRANT_HOME"]))
        assert_equal expected, @env.home_path
      end

      should "move the old home directory to the new location" do
        new_path = @home_path.join(".vagrant.d")
        old_path = @home_path.join(".vagrant")
        old_path.mkdir

        # Get the home path
        ENV["VAGRANT_HOME"] = new_path.to_s

        assert !new_path.exist?
        assert_equal new_path, @env.home_path
        assert !old_path.exist?
        assert new_path.exist?
      end

      should "not move the old home directory if the new one already exists" do
        new_path = @home_path.join(".vagrant.d")
        new_path.mkdir

        old_path = @home_path.join(".vagrant")
        old_path.mkdir

        # Get the home path
        ENV["VAGRANT_HOME"] = new_path.to_s

        assert new_path.exist?
        assert_equal new_path, @env.home_path
        assert old_path.exist?
        assert new_path.exist?
      end
    end

    context "temp path" do
      should "return the home path joined with 'tmp'" do
        assert_equal @env.home_path.join("tmp"), @env.tmp_path
      end
    end

    context "boxes path" do
      should "return the home path joined with 'tmp'" do
        assert_equal @env.home_path.join("boxes"), @env.boxes_path
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

    should "return true if VM length is 1 and a sub-VM is defined" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
      vf

      assert env.multivm?
    end

    should "return false if only default VM exists" do
      assert !vagrant_env.multivm?
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
      env = @klass.new(:cwd => vagrantfile)
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

    should "return the parent's global data if a parent exists" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
      vf

      result = env.global_data
      assert env.vms[:web].env.global_data.equal?(result)
    end
  end

  context "loading logger" do
    should "lazy load the logger only once" do
      env = vagrant_env
      result = env.logger
      assert result === env.logger
    end

    should "return the parent's logger if a parent exists" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
      vf

      assert env.logger === env.vms[:web].env.logger
    end
  end

  context "loading the root path" do
    should "should walk the parent directories looking for rootfile" do
      paths = [Pathname.new("/foo/bar/baz"),
               Pathname.new("/foo/bar"),
               Pathname.new("/foo"),
               Pathname.new("/")
              ]

      rootfile = "Foo"

      search_seq = sequence("search_seq")
      paths.each do |path|
        File.expects(:exist?).with(path.join(rootfile).to_s).returns(false).in_sequence(search_seq)
        File.expects(:exist?).with(path).returns(true).in_sequence(search_seq) if !path.root?
      end

      assert !@klass.new(:cwd => paths.first, :vagrantfile_name => rootfile).root_path
    end

    should "should set the path for the rootfile" do
      rootfile = "Foo"
      path = Pathname.new(File.expand_path("/foo"))
      File.expects(:exist?).with(path.join(rootfile).to_s).returns(true)

      assert_equal path, @klass.new(:cwd => path, :vagrantfile_name => rootfile).root_path
    end

    should "not infinite loop on relative paths" do
      assert @klass.new(:cwd => "../test").root_path.nil?
    end

    should "only load the root path once" do
      rootfile = "foo"
      env = @klass.new(:vagrantfile_name => rootfile)
      File.expects(:exist?).with(env.cwd.join(rootfile).to_s).returns(true).once

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

  context "locking" do
    setup do
      @instance = @klass.new(:lock_path => Tempfile.new('vagrant-test').path)
    end

    should "allow nesting locks" do
      assert_nothing_raised do
        @instance.lock do
          @instance.lock do
            # Nothing
          end
        end
      end
    end

    should "raise an exception if an environment already has a lock" do
      @another = @klass.new(:lock_path => @instance.lock_path)

      # Create first locked thread which should succeed
      first = Thread.new do
        begin
          @instance.lock do
            Thread.current[:locked] = true
            loop { sleep 1000 }
          end
        rescue Vagrant::Errors::EnvironmentLockedError
          Thread.current[:locked] = false
        end
      end

      # Wait until the first thread has acquired the lock
      loop do
        break if first[:locked] || !first.alive?
        Thread.pass
      end

      # Verify that the fist got the lock
      assert first[:locked]

      # Create second locked thread which should fail
      second = Thread.new do
        begin
          @another.lock do
            Thread.current[:error] = false
          end
        rescue Vagrant::Errors::EnvironmentLockedError
          Thread.current[:error] = true
        end
      end

      # Wait for the second to end and verify it failed
      second.join
      assert second[:error]

      # Make sure both threads are killed
      first.kill
      second.kill
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

  context "accessing the box collection" do
    should "create a box collection representing the environment" do
      env = vagrant_env
      assert env.boxes.is_a?(Vagrant::BoxCollection)
      assert_equal env, env.boxes.env
    end

    should "not load the environment if its already loaded" do
      env = vagrant_env
      env.expects(:load!).never
      env.boxes
    end

    should "return the parent's box collection if it has one" do
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.define :web
        config.vm.define :db
      vf

      assert env.vms[:web].env.boxes.equal?(env.boxes)
    end
  end

  context "accessing the current box" do
    should "return the box that is specified in the config" do
      vagrant_box("foo")
      env = vagrant_env(vagrantfile(<<-vf))
        config.vm.box = "foo"
      vf

      assert env.box
      assert_equal "foo", env.box.name
    end
  end

  context "accessing the VMs hash" do
    should "load the environment if its not already loaded" do
      env = @klass.new(:cwd => vagrantfile)
      assert !env.loaded?
      env.vms
      assert env.loaded?
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
    context "overall load method" do
      should "load! should call proper sequence and return itself" do
        env = @klass.new(:cwd => vagrantfile)
        call_seq = sequence("call_sequence")
        @klass.expects(:check_virtualbox!).once.in_sequence(call_seq)
        env.expects(:load_config!).once.in_sequence(call_seq)
        assert_equal env, env.load!
      end
    end

    context "loading config" do
      setup do
        clean_paths
        @env = @klass.new(:cwd => vagrantfile)
      end

      def create_box_vagrantfile
        vagrantfile(vagrant_box("box"), <<-FILE)
          config.package.name = "box.box"
          config.vm.base_mac = "set"
        FILE
      end

      def create_home_vagrantfile
        vagrantfile(home_path, 'config.package.name = "home.box"')
      end

      def create_root_vagrantfile
        vagrantfile(@env.root_path, 'config.package.name = "root.box"')
      end

      should "load from the project root" do
        assert_equal "package.box", @env.config.package.name
      end

      should "load from box if specified" do
        create_box_vagrantfile
        vagrantfile(@env.root_path, "config.vm.box = 'box'")

        assert_equal "box.box", @env.primary_vm.env.config.package.name
      end

      should "load from home path if exists" do
        create_home_vagrantfile
        assert_equal "home.box", @env.config.package.name
      end

      should "load from root path" do
        create_home_vagrantfile
        create_root_vagrantfile
        assert_equal "root.box", @env.config.package.name
      end

      should "load from a sub-vm configuration if environment represents a VM" do
        create_home_vagrantfile
        create_box_vagrantfile
        vagrantfile(@env.root_path, <<-vf)
          config.package.name = "root.box"
          config.vm.define :web do |web|
            web.vm.box = "box"
            web.package.name = "web.box"
          end
        vf

        assert_equal "root.box", @env.config.package.name
        assert_equal "web.box", @env.vms[:web].env.config.package.name
        assert_equal "set", @env.vms[:web].env.config.vm.base_mac
      end

      should "be able to reload config" do
        vagrantfile(@env.root_path, "config.vm.box = 'box'")

        # First load the config normally
        @env.load_config!
        assert_equal "box", @env.config.vm.box
        assert_not_equal "set", @env.config.vm.base_mac

        # Modify the Vagrantfile and reload it, then verify new results
        # are available
        vagrantfile(@env.root_path, "config.vm.base_mac = 'set'")
        @env.reload_config!
        assert_equal "set", @env.config.vm.base_mac
      end
    end

    context "loading home directory" do
      setup do
        @env = vagrant_env

        File.stubs(:directory?).returns(true)
        FileUtils.stubs(:mkdir_p)
      end

      should "create each directory if it doesn't exist" do
        create_seq = sequence("create_seq")
        File.stubs(:directory?).returns(false)
        @klass::HOME_SUBDIRS.each do |subdir|
          FileUtils.expects(:mkdir_p).with(@env.home_path.join(subdir)).in_sequence(create_seq)
        end

        @env.load_home_directory!
      end

      should "not create directories if they exist" do
        File.stubs(:directory?).returns(true)
        FileUtils.expects(:mkdir_p).never
        @env.load_home_directory!
      end
    end

    context "loading the UUID out from the persisted dotfile" do
      setup do
        @env = vagrant_env
      end

      should "load all the VMs from the dotfile" do
        @env.local_data[:active] = { "foo" => "bar", "bar" => "baz" }

        results = {}
        @env.local_data[:active].each do |key, value|
          vm = mock("vm#{key}")
          Vagrant::VM.expects(:find).with(value, @env, key.to_sym).returns(vm)
          results[key.to_sym] = vm
        end

        returned = @env.load_vms!

        results.each do |key, value|
          assert_equal value, returned[key]
        end
      end

      should "uuid should be nil if local data contains nothing" do
        assert @env.local_data.empty? # sanity
        @env.load_vms!
        assert_nil @env.vm
      end
    end
  end
end
