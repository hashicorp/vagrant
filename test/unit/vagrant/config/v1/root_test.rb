require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Config::V1::Root do
  include_context "unit"

  it "should provide access to config objects" do
    foo_class = Class.new
    map       = { :foo => foo_class }

    instance  = described_class.new(map)
    foo       = instance.foo
    foo.should be_kind_of(foo_class)
    instance.foo.should eql(foo)
  end

  it "should raise a proper NoMethodError if a config key doesn't exist" do
    instance = described_class.new({})
    expect { instance.foo }.to raise_error(NoMethodError)
  end

  it "can be created with initial state" do
    instance = described_class.new({}, { :foo => "bar" })
    instance.foo.should == "bar"
  end

  it "should return internal state" do
    map      = { "foo" => Object, "bar" => Object }
    instance = described_class.new(map)
    instance.__internal_state.should == {
      "config_map" => map,
      "keys"       => {}
    }
  end
end
