require File.expand_path("../../base", __FILE__)

require "pathname"

require "support/tempdir"

describe Vagrant::Environment do
  include_context "unit"

  describe "current working directory" do
    it "is the cwd by default" do
      described_class.new.cwd.should == Pathname.new(Dir.pwd)
    end

    it "is set to the cwd given" do
      instance = described_class.new(:cwd => "foobarbaz")
      instance.cwd.should == Pathname.new("foobarbaz")
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
  end

  describe "loading configuration" do
    let(:home_path) { Pathname.new(Tempdir.new.path) }
    let(:instance)  { described_class.new(:home_path => home_path) }

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

    it "should load VM configuration" do
      environment = isolated_environment do |env|
        env.vagrantfile(<<-VF)
Vagrant::Config.run do |config|
  config.vagrant.dotfile_name = "foo"
end
VF
      end

      env = environment.create_vagrant_env
      env.config.for_vm("default").vm.name.should == "default"
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
      env.config.for_vm("foo").ssh.port.should == 100
      env.config.for_vm("bar").ssh.port.should == 200
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
      env.config.for_vm("default").ssh.port.should == 100
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
