require File.expand_path("../../base", __FILE__)

describe Vagrant::BoxCollection do
  include_context "unit"

  let(:environment) { isolated_environment }
  let(:instance)    { described_class.new(environment.boxes_dir) }

  it "should list all available boxes" do
    # No boxes yet.
    instance.length.should == 0

    # Add some boxes to the environment and try again
    environment.box("foo")
    environment.box("bar")
    instance.reload!
    instance.length.should == 2
  end

  describe "finding" do
    it "should return nil if it can't find the box" do
      instance.find("foo").should be_nil
    end

    it "should return a box instance for any boxes it does find" do
      environment.box("foo")
      result = instance.find("foo")
      result.should be_kind_of(Vagrant::Box)
      result.name.should == "foo"
    end
  end
end
