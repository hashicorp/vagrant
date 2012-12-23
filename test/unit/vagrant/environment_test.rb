require File.expand_path("../../base", __FILE__)
require "pathname"

require "vagrant/util/file_mode"

require "support/tempdir"

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

  describe "current working directory" do
    it "is the cwd by default" do
      with_temp_env("VAGRANT_CWD" => nil) do
        described_class.new.cwd.should == Pathname.new(Dir.pwd)
      end
    end

    it "is set to the cwd given" do
      directory = File.dirname(__FILE__)
      instance = described_class.new(:cwd => directory)
      instance.cwd.should == Pathname.new(directory)
    end

    it "is set to the environmental variable VAGRANT_CWD" do
      directory = File.dirname(__FILE__)
      instance = with_temp_env("VAGRANT_CWD" => directory) do
        described_class.new
      end

      instance.cwd.should == Pathname.new(directory)
    end

    it "raises an exception if the CWD doesn't exist" do
      expect { described_class.new(:cwd => "doesntexist") }.
        to raise_error(Vagrant::Errors::EnvironmentNonExistentCWD)
    end
  end

  describe "home path" do
    it "is set to the home path given" do
      dir = Tempdir.new.path
      instance = described_class.new(:home_path => dir)
      instance.home_path.should == Pathname.new(dir)
    end

    it "is set to the environmental variable VAGRANT_HOME" do
      pending "A good temporary ENV thing"
    end

    it "is set to the DEFAULT_HOME by default" do
      expected = Pathname.new(File.expand_path(described_class::DEFAULT_HOME))
      described_class.new.home_path.should == expected
    end

    it "throws an exception if inaccessible" do
      expect {
        described_class.new(:home_path => "/")
      }.to raise_error(Vagrant::Errors::HomeDirectoryNotAccessible)
    end
  end

  describe "default provider" do
    it "should return virtualbox" do
      instance.default_provider.should == :virtualbox
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

  describe "primary machine" do
    it "should be the only machine if not a multi-machine environment" do
      instance.primary_machine(:dummy).name.should == instance.machine_names.first
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
      env.primary_machine(:dummy).name.should == :bar
    end
  end

  describe "loading configuration" do
    it "should load global configuration" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant.configure("2") do |config|
  config.vagrant.dotfile_name = "foo"
end
VF
      end

      env = environment.create_vagrant_env
      env.config_global.vagrant.dotfile_name.should == "foo"
    end

    it "should load from a custom Vagrantfile" do
      environment = isolated_environment do |env|
        env.file("non_standard_name", <<-VF)
Vagrant.configure("2") do |config|
  config.vagrant.dotfile_name = "custom"
end
VF
      end

      env = environment.create_vagrant_env(:vagrantfile_name => "non_standard_name")
      env.config_global.vagrant.dotfile_name.should == "custom"
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

  describe "getting a machine" do
    # A helper to register a provider for use in tests.
    def register_provider(name)
      provider_cls = Class.new(Vagrant.plugin("2", :provider))

      register_plugin("2") do |p|
        p.provider(name) { provider_cls }
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
  config.vagrant.dotfile_name = "foo"
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
      machine.config.vagrant.dotfile_name.should == "foo"
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
