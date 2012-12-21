require File.expand_path("../../base", __FILE__)
require "pathname"

require "vagrant/util/file_mode"

require "support/tempdir"

describe Vagrant::Environment do
  include_context "unit"

  let(:home_path) { Pathname.new(Tempdir.new.path) }
  let(:instance)  { described_class.new(:home_path => home_path) }

  describe "current working directory" do
    it "is the cwd by default" do
      described_class.new.cwd.should == Pathname.new(Dir.pwd)
    end

    it "is set to the cwd given" do
      directory = File.dirname(__FILE__)
      instance = described_class.new(:cwd => directory)
      instance.cwd.should == Pathname.new(directory)
    end

    it "is set to the environmental variable VAGRANT_CWD" do
      pending "A good temporary ENV thing"
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

  describe "action registry" do
    it "has an action registry" do
      instance.action_registry.should be_kind_of(Vagrant::Registry)
    end

    it "should have the built-in actions in the registry" do
      instance.action_registry.get(:provision).should_not be_nil
    end
  end

  describe "primary VM" do
    before do
      # This is really nasty but we do this to remove the dependency on
      # having VirtualBox installed to run tests.
      Vagrant::Driver::VirtualBox.stub(:new) do |uuid|
        double("vm-#{uuid}")
      end
    end

    it "should be the only VM if not a multi-VM environment" do
      instance.primary_vm.should == instance.vms.values.first
    end

    it "should be the VM marked as the primary" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant::Config.run do |config|
  config.vm.define :foo
  config.vm.define :bar, :primary => true
end
VF
      end

      env = environment.create_vagrant_env
      env.primary_vm.should == env.vms[:bar]
    end
  end

  describe "loading configuration" do
    it "should load global configuration" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant::Config.run do |config|
  config.vagrant.dotfile_name = "foo"
end
VF
      end

      env = environment.create_vagrant_env
      env.config.global.vagrant.dotfile_name.should == "foo"
    end

    it "should load from a custom Vagrantfile" do
      environment = isolated_environment do |env|
        env.file("non_standard_name", <<-VF)
Vagrant::Config.run do |config|
  config.vagrant.dotfile_name = "custom"
end
VF
      end

      env = environment.create_vagrant_env(:vagrantfile_name => "non_standard_name")
      env.config.global.vagrant.dotfile_name.should == "custom"
    end

    it "should load VM configuration" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant::Config.run do |config|
  config.vagrant.dotfile_name = "foo"
end
VF
      end

      env = environment.create_vagrant_env
      env.config.for_vm(:default).vm.name.should == :default
    end

    it "should load VM configuration with multiple VMs" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant::Config.run do |config|
  config.vm.define :foo do |vm|
    vm.ssh.port = 100
  end

  config.vm.define :bar do |vm|
    vm.ssh.port = 200
  end
end
VF
      end

      env = environment.create_vagrant_env
      env.config.for_vm(:foo).ssh.port.should == 100
      env.config.for_vm(:bar).ssh.port.should == 200
    end

    it "should load box configuration" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant::Config.run do |config|
  config.vm.box = "base"
end
VF

        env.box("base", <<-VF)
Vagrant::Config.run do |config|
  config.ssh.port = 100
end
VF
      end

      env = environment.create_vagrant_env
      env.config.for_vm(:default).ssh.port.should == 100
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
end
