require File.expand_path("../../../base", __FILE__)

describe Vagrant::Action::Registry do
  let(:instance) { described_class.new }

  it "should return nil for nonexistent actions" do
    instance.get("foo").should be_nil
  end

  it "should register an action without calling the block yet" do
    expect do
      instance.register("foo") do
        raise Exception, "BOOM!"
      end
    end.to_not raise_error
  end

  it "should call and return the result of a block when asking for the action" do
    object = Object.new
    instance.register("foo") do
      object
    end

    instance.get("foo").should eql(object)
  end
end
