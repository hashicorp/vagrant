require File.expand_path("../../base", __FILE__)

describe Vagrant::BoxCollection do
  include_context "unit"

  let(:environment) { isolated_environment }
  let(:action_runner) { double("action runner") }
  let(:instance)    { described_class.new(environment.boxes_dir, action_runner) }

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

  it "should throw an error if the box already exists when adding" do
    environment.box("foo")
    expect { instance.add("foo", "bar") }.to raise_error(Vagrant::Errors::BoxAlreadyExists)
  end

  it "should add the box" do
    name = "foo"
    url  = "bar"

    # Test the invocation of the action runner with the proper name
    # and parameters. We leave the testing of the actual stack to
    # acceptance tests, and individual pieces to unit tests of each
    # step.
    options = {
      :box_name => name,
      :box_url => url,
      :box_directory => instance.directory.join(name)
    }
    action_runner.should_receive(:run).with(:box_add, options)

    instance.add(name, url)
  end
end
