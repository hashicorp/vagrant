require File.expand_path("../../base", __FILE__)

require "pathname"

describe Vagrant::BoxCollection2 do
  include_context "unit"

  let(:box_class)   { Vagrant::Box2 }
  let(:environment) { isolated_environment }
  let(:instance)    { described_class.new(environment.boxes_dir) }

  describe "finding" do
    it "should return nil if the box does not exist" do
      instance.find("foo", :i_dont_exist).should be_nil
    end

    it "should return a box if the box does exist" do
      # Create the "box"
      environment.box2("foo", :virtualbox)

      # Actual test
      result = instance.find("foo", :virtualbox)
      result.should_not be_nil
      result.should be_kind_of(box_class)
      result.name.should == "foo"
    end

    it "should throw an exception if it is a v1 box" do
      # Create a V1 box
      box_dir = environment.boxes_dir.join("foo")
      box_dir.mkpath
      box_dir.join("box.ovf").open("w") { |f| f.write("") }

      # Test!
      expect { instance.find("foo", :virtualbox) }.
        to raise_error(Vagrant::Errors::BoxUpgradeRequired)
    end
  end
end
