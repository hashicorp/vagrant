require File.expand_path("../../base", __FILE__)

require "pathname"

describe Vagrant::Environment do
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
      instance = described_class.new(:home_path => "/tmp/foo")
      instance.home_path.should == Pathname.new("/tmp/foo")
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
    let(:home_path) { Pathname.new("/tmp/foo") }
    let(:instance)  { described_class.new(:home_path => home_path) }

    it "should load global configuration" do
      File.open(home_path.join("Vagrantfile"), "w+") do |f|
        f.write(<<-VF)
Vagrant::Config.run do |config|
  config.vagrant.dotfile_name = "foo"
end
VF
      end

      instance.config.global.vagrant.dotfile_name.should == "foo"
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
