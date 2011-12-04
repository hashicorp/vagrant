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
