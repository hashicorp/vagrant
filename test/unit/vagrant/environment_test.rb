require File.expand_path("../../base", __FILE__)
require "json"
require "pathname"
require "tempfile"
require "tmpdir"

require "vagrant/util/file_mode"

describe Vagrant::Environment do
  include_context "unit"

  let(:env) do
    isolated_environment.tap do |e|
      e.box2("base", :virtualbox)
      e.vagrantfile <<-VF
      Vagrant.configure("2") do |config|
        config.vm.box = "base"
      end
      VF
    end
  end

  let(:instance)  { env.create_vagrant_env }

  subject { instance }

  describe "active machines" do
    it "should be empty if the machines folder doesn't exist" do
      folder = instance.local_data_path.join("machines")
      folder.should_not be_exist

      instance.active_machines.should be_empty
    end

    it "should return the name and provider of active machines" do
      machines = instance.local_data_path.join("machines")

      # Valid machine, with "foo" and virtualbox
      machine_foo = machines.join("foo/virtualbox")
      machine_foo.mkpath
      machine_foo.join("id").open("w+") { |f| f.write("") }

      # Invalid machine (no ID)
      machine_bar = machines.join("bar/virtualbox")
      machine_bar.mkpath

      instance.active_machines.should == [[:foo, :virtualbox]]
    end
  end

  describe "batching" do
    let(:batch) do
      double("batch") do |b|
        b.stub(:run)
      end
    end

    context "without the disabling env var" do
      it "should run without disabling parallelization" do
        with_temp_env("VAGRANT_NO_PARALLEL" => nil) do
          Vagrant::BatchAction.should_receive(:new).with(true).and_return(batch)
          batch.should_receive(:run)

          instance.batch {}
        end
      end

      it "should run with disabling parallelization if explicit" do
        with_temp_env("VAGRANT_NO_PARALLEL" => nil) do
          Vagrant::BatchAction.should_receive(:new).with(false).and_return(batch)
          batch.should_receive(:run)

          instance.batch(false) {}
        end
      end
    end

    context "with the disabling env var" do
      it "should run with disabling parallelization" do
        with_temp_env("VAGRANT_NO_PARALLEL" => "yes") do
          Vagrant::BatchAction.should_receive(:new).with(false).and_return(batch)
          batch.should_receive(:run)

          instance.batch {}
        end
      end
    end
  end

  describe "current working directory" do
    it "is the cwd by default" do
      Dir.mktmpdir do |temp_dir|
        Dir.chdir(temp_dir) do
          with_temp_env("VAGRANT_CWD" => nil) do
            described_class.new.cwd.should == Pathname.new(Dir.pwd)
          end
        end
      end
    end

    it "is set to the cwd given" do
      Dir.mktmpdir do |directory|
        instance = described_class.new(:cwd => directory)
        instance.cwd.should == Pathname.new(directory)
      end
    end

    it "is set to the environmental variable VAGRANT_CWD" do
      Dir.mktmpdir do |directory|
        instance = with_temp_env("VAGRANT_CWD" => directory) do
          described_class.new
        end

        instance.cwd.should == Pathname.new(directory)
      end
    end

    it "raises an exception if the CWD doesn't exist" do
      expect { described_class.new(:cwd => "doesntexist") }.
        to raise_error(Vagrant::Errors::EnvironmentNonExistentCWD)
    end
  end

  describe "default provider" do
    it "is virtualbox without any environmental variable" do
      with_temp_env("VAGRANT_DEFAULT_PROVIDER" => nil) do
        subject.default_provider.should == :virtualbox
      end
    end

    it "is whatever the environmental variable is if set" do
      with_temp_env("VAGRANT_DEFAULT_PROVIDER" => "foo") do
        subject.default_provider.should == :foo
      end
    end
  end

  describe "home path" do
    it "is set to the home path given" do
      Dir.mktmpdir do |dir|
        instance = described_class.new(:home_path => dir)
        instance.home_path.should == Pathname.new(dir)
      end
    end

    it "is set to the environmental variable VAGRANT_HOME" do
      Dir.mktmpdir do |dir|
        instance = with_temp_env("VAGRANT_HOME" => dir) do
          described_class.new
        end

        instance.home_path.should == Pathname.new(dir)
      end
    end

    context "default home path" do
      before :each do
        Vagrant::Util::Platform.stub(:windows? => false)
      end

      it "is set to '~/.vagrant.d' by default" do
        expected = Pathname.new(File.expand_path("~/.vagrant.d"))
        described_class.new.home_path.should == expected
      end

      it "is set to '~/.vagrant.d' if on Windows but no USERPROFILE" do
        Vagrant::Util::Platform.stub(:windows? => true)

        expected = Pathname.new(File.expand_path("~/.vagrant.d"))

        with_temp_env("USERPROFILE" => nil) do
          described_class.new.home_path.should == expected
        end
      end

      it "is set to '%USERPROFILE%/.vagrant.d' if on Windows and USERPROFILE is set" do
        Vagrant::Util::Platform.stub(:windows? => true)

        Dir.mktmpdir do |dir|
          expected = Pathname.new(File.expand_path("#{dir}/.vagrant.d"))

          with_temp_env("USERPROFILE" => dir) do
            described_class.new.home_path.should == expected
          end
        end
      end
    end

    it "throws an exception if inaccessible" do
      expect {
        described_class.new(:home_path => "/")
      }.to raise_error(Vagrant::Errors::HomeDirectoryNotAccessible)
    end
  end

  describe "local data path" do
    it "is set to the proper default" do
      default = instance.root_path.join(described_class::DEFAULT_LOCAL_DATA)
      instance.local_data_path.should == default
    end

    it "is expanded relative to the cwd" do
      instance = described_class.new(:local_data_path => "foo")
      instance.local_data_path.should == instance.cwd.join("foo")
    end

    it "is set to the given value" do
      Dir.mktmpdir do |dir|
        instance = described_class.new(:local_data_path => dir)
        instance.local_data_path.to_s.should == dir
      end
    end

    describe "upgrading V1 dotfiles" do
      let(:v1_dotfile_tempfile) { Tempfile.new("vagrant") }
      let(:v1_dotfile)          { Pathname.new(v1_dotfile_tempfile.path) }
      let(:local_data_path)     { v1_dotfile_tempfile.path }
      let(:instance) { described_class.new(:local_data_path => local_data_path) }

      it "should be fine if dotfile is empty" do
        v1_dotfile.open("w+") do |f|
          f.write("")
        end

        expect { instance }.to_not raise_error
        Pathname.new(local_data_path).should be_directory
      end

      it "should upgrade all active VMs" do
        active_vms = {
          "foo" => "foo_id",
          "bar" => "bar_id"
        }

        v1_dotfile.open("w+") do |f|
          f.write(JSON.dump({
            "active" => active_vms
          }))
        end

        expect { instance }.to_not raise_error

        local_data_pathname = Pathname.new(local_data_path)
        foo_id_file = local_data_pathname.join("machines/foo/virtualbox/id")
        foo_id_file.should be_file
        foo_id_file.read.should == "foo_id"

        bar_id_file = local_data_pathname.join("machines/bar/virtualbox/id")
        bar_id_file.should be_file
        bar_id_file.read.should == "bar_id"
      end

      it "should raise an error if invalid JSON" do
        v1_dotfile.open("w+") do |f|
          f.write("bad")
        end

        expect { instance }.
          to raise_error(Vagrant::Errors::DotfileUpgradeJSONError)
      end
    end
  end

  describe "copying the private SSH key" do
    it "copies the SSH key into the home directory" do
      env = isolated_environment
      instance = described_class.new(:home_path => env.homedir)

      pk = env.homedir.join("insecure_private_key")
      pk.should be_exist
      Vagrant::Util::FileMode.from_octal(pk.stat.mode).should == "600"
    end
  end

  it "has a box collection pointed to the proper directory" do
    collection = instance.boxes
    collection.should be_kind_of(Vagrant::BoxCollection)
    collection.directory.should == instance.boxes_path
  end

  describe "action runner" do
    it "has an action runner" do
      instance.action_runner.should be_kind_of(Vagrant::Action::Runner)
    end

    it "has a `ui` in the globals" do
      result = nil
      callable = lambda { |env| result = env[:ui] }

      instance.action_runner.run(callable)
      result.should eql(instance.ui)
    end
  end

  describe "#hook" do
    it "should call the action runner with the proper hook" do
      hook_name = :foo

      instance.action_runner.should_receive(:run).with do |callable, env|
        env[:action_name].should == hook_name
      end

      instance.hook(hook_name)
    end

    it "should return the result of the action runner run" do
      instance.action_runner.should_receive(:run).and_return(:foo)

      instance.hook(:bar).should == :foo
    end
  end

  describe "primary machine name" do
    it "should be the only machine if not a multi-machine environment" do
      instance.primary_machine_name.should == instance.machine_names.first
    end

    it "should be the machine marked as the primary" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
  config.vm.define :foo
  config.vm.define :bar, :primary => true
end
VF

        env.box2("base", :virtualbox)
      end

      env = environment.create_vagrant_env
      env.primary_machine_name.should == :bar
    end

    it "should be nil if no primary is specified in a multi-machine environment" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
  config.vm.define :foo
  config.vm.define :bar
end
VF

        env.box2("base", :virtualbox)
      end

      env = environment.create_vagrant_env
      env.primary_machine_name.should be_nil
    end
  end

  describe "loading configuration" do
    it "should load global configuration" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 200
end
VF
      end

      env = environment.create_vagrant_env
      env.config_global.ssh.port.should == 200
    end

    it "should load from a custom Vagrantfile" do
      environment = isolated_environment do |env|
        env.file("non_standard_name", <<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 200
end
VF
      end

      env = environment.create_vagrant_env(:vagrantfile_name => "non_standard_name")
      env.config_global.ssh.port.should == 200
    end

    it "should load from a custom Vagrantfile specified by env var" do
      environment = isolated_environment do |env|
        env.file("some_other_name", <<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 400
end
VF
      end

      env = with_temp_env("VAGRANT_VAGRANTFILE" => "some_other_name") do
        environment.create_vagrant_env
      end

      env.config_global.ssh.port.should == 400
    end
  end

  describe "ui" do
    it "should be a silent UI by default" do
      described_class.new.ui.should be_kind_of(Vagrant::UI::Silent)
    end

    it "should be a UI given in the constructor" do
      # Create a custom UI for our test
      class CustomUI < Vagrant::UI::Interface; end

      instance = described_class.new(:ui_class => CustomUI)
      instance.ui.should be_kind_of(CustomUI)
    end
  end

  describe "#unload" do
    it "should run the unload hook" do
      instance.should_receive(:hook).with(:environment_unload).once
      instance.unload
    end
  end

  describe "getting a machine" do
    # A helper to register a provider for use in tests.
    def register_provider(name, config_class=nil, options=nil)
      provider_cls = Class.new(Vagrant.plugin("2", :provider))

      register_plugin("2") do |p|
        p.provider(name, options) { provider_cls }

        if config_class
          p.config(name, :provider) { config_class }
        end
      end

      provider_cls
    end

    it "should return a machine object with the correct provider" do
      # Create a provider
      foo_provider = register_provider("foo")

      # Create the configuration
      isolated_env = isolated_environment do |e|
        e.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
  config.vm.define "foo"
end
VF

        e.box2("base", :foo)
      end

      # Verify that we can get the machine
      env = isolated_env.create_vagrant_env
      machine = env.machine(:foo, :foo)
      machine.should be_kind_of(Vagrant::Machine)
      machine.name.should == :foo
      machine.provider.should be_kind_of(foo_provider)
      machine.provider_config.should be_nil
    end

    it "should return a machine object with the machine configuration" do
      # Create a provider
      foo_config = Class.new(Vagrant.plugin("2", :config)) do
        attr_accessor :value
      end

      foo_provider = register_provider("foo", foo_config)

      # Create the configuration
      isolated_env = isolated_environment do |e|
        e.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
  config.vm.define "foo"

  config.vm.provider :foo do |fooconfig|
    fooconfig.value = 100
  end
end
VF

        e.box2("base", :foo)
      end

      # Verify that we can get the machine
      env = isolated_env.create_vagrant_env
      machine = env.machine(:foo, :foo)
      machine.should be_kind_of(Vagrant::Machine)
      machine.name.should == :foo
      machine.provider.should be_kind_of(foo_provider)
      machine.provider_config.value.should == 100
    end

    it "should cache the machine objects by name and provider" do
      # Create a provider
      foo_provider = register_provider("foo")
      bar_provider = register_provider("bar")

      # Create the configuration
      isolated_env = isolated_environment do |e|
        e.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
  config.vm.define "vm1"
  config.vm.define "vm2"
end
VF

        e.box2("base", :foo)
        e.box2("base", :bar)
      end

      env = isolated_env.create_vagrant_env
      vm1_foo = env.machine(:vm1, :foo)
      vm1_bar = env.machine(:vm1, :bar)
      vm2_foo = env.machine(:vm2, :foo)

      vm1_foo.should eql(env.machine(:vm1, :foo))
      vm1_bar.should eql(env.machine(:vm1, :bar))
      vm1_foo.should_not eql(vm1_bar)
      vm2_foo.should eql(env.machine(:vm2, :foo))
    end

    it "should load a machine without a box" do
      register_provider("foo")

      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "i-dont-exist"
end
VF
      end

      env = environment.create_vagrant_env
      machine = env.machine(:default, :foo)
      machine.box.should be_nil
    end

    it "should load the machine configuration" do
      register_provider("foo")

      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 1
  config.vm.box = "base"

  config.vm.define "vm1" do |inner|
    inner.ssh.port = 100
  end
end
VF

        env.box2("base", :foo)
      end

      env = environment.create_vagrant_env
      machine = env.machine(:vm1, :foo)
      machine.config.ssh.port.should == 100
      machine.config.vm.box.should == "base"
    end

    it "should load the box configuration for a V2 box" do
      register_provider("foo")

      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
end
VF

        env.box2("base", :foo, :vagrantfile => <<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 100
end
VF
      end

      env = environment.create_vagrant_env
      machine = env.machine(:default, :foo)
      machine.config.ssh.port.should == 100
    end

    it "should load the box configuration for a V2 box and custom Vagrantfile name" do
      register_provider("foo")

      environment = isolated_environment do |env|
        env.file("some_other_name", <<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
end
VF

        env.box2("base", :foo, :vagrantfile => <<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 100
end
VF
      end

      env = with_temp_env("VAGRANT_VAGRANTFILE" => "some_other_name") do
        environment.create_vagrant_env
      end

      machine = env.machine(:default, :foo)
      machine.config.ssh.port.should == 100
    end

    it "should load the box configuration for other formats for a V2 box" do
      register_provider("foo", nil, box_format: "bar")

      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
end
VF

        env.box2("base", :bar, :vagrantfile => <<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 100
end
VF
      end

      env = environment.create_vagrant_env
      machine = env.machine(:default, :foo)
      machine.config.ssh.port.should == 100
    end

    it "prefer sooner formats when multiple box formats are available" do
      register_provider("foo", nil, box_format: ["fA", "fB"])

      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
end
VF

        env.box2("base", :fA, :vagrantfile => <<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 100
end
VF

        env.box2("base", :fB, :vagrantfile => <<-VF)
Vagrant.configure("2") do |config|
  config.ssh.port = 200
end
VF
      end

      env = environment.create_vagrant_env
      machine = env.machine(:default, :foo)
      machine.config.ssh.port.should == 100
    end

    it "should load the provider override if set" do
      register_provider("bar")
      register_provider("foo")

      isolated_env = isolated_environment do |e|
        e.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "foo"

  config.vm.provider :foo do |_, c|
    c.vm.box = "bar"
  end
end
VF
      end

      env = isolated_env.create_vagrant_env
      foo_vm = env.machine(:default, :foo)
      bar_vm = env.machine(:default, :bar)
      foo_vm.config.vm.box.should == "bar"
      bar_vm.config.vm.box.should == "foo"
    end

    it "should reload the cache if refresh is set" do
      # Create a provider
      foo_provider = register_provider("foo")

      # Create the configuration
      isolated_env = isolated_environment do |e|
        e.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.box = "base"
end
VF

        e.box2("base", :foo)
      end

      env = isolated_env.create_vagrant_env
      vm1 = env.machine(:default, :foo)
      vm2 = env.machine(:default, :foo, true)
      vm3 = env.machine(:default, :foo)

      vm1.should_not eql(vm2)
      vm2.should eql(vm3)
    end

    it "should raise an error if the VM is not found" do
      expect { instance.machine("i-definitely-dont-exist", :virtualbox) }.
        to raise_error(Vagrant::Errors::MachineNotFound)
    end

    it "should raise an error if the provider is not found" do
      expect { instance.machine(:default, :lol_no) }.
        to raise_error(Vagrant::Errors::ProviderNotFound)
    end
  end

  describe "getting machine names" do
    it "should return the default machine if no multi-VM is used" do
      # Create the config
      isolated_env = isolated_environment do |e|
        e.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
end
VF
      end

      env = isolated_env.create_vagrant_env
      env.machine_names.should == [:default]
    end

    it "should return the machine names in order" do
      # Create the config
      isolated_env = isolated_environment do |e|
        e.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vm.define "foo"
  config.vm.define "bar"
end
VF
      end

      env = isolated_env.create_vagrant_env
      env.machine_names.should == [:foo, :bar]
    end
  end
end
