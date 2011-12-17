require File.expand_path("../../../base", __FILE__)

describe Vagrant::Command::Base do
  describe "splitting the main and subcommand args" do
    let(:instance) do
      Class.new(described_class) do
        # Make the method public since it is normal protected
        public :split_main_and_subcommand
      end.new
    end

    it "should work when given all 3 parts" do
      result = instance.split_main_and_subcommand(["-v", "status", "-h", "-v"])
      result.should == [["-v"], "status", ["-h", "-v"]]
    end

    it "should work when given only a subcommand and args" do
      result = instance.split_main_and_subcommand(["status", "-h"])
      result.should == [[], "status", ["-h"]]
    end

    it "should work when given only main flags" do
      result = instance.split_main_and_subcommand(["-v", "-h"])
      result.should == [["-v", "-h"], nil, []]
    end

    it "should work when given only a subcommand" do
      result = instance.split_main_and_subcommand(["status"])
      result.should == [[], "status", []]
    end
  end
end
