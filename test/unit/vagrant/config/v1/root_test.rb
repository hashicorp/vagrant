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

  it "can be created with initial state" do
    instance = described_class.new({}, { :foo => "bar" })
    instance.foo.should == "bar"
  end

  it "should return internal state" do
    map      = { "foo" => Object, "bar" => Object }
    instance = described_class.new(map)
    instance.__internal_state.should == {
      "config_map" => map,
      "keys"       => {},
      "missing_key_calls" => Set.new
    }
  end

  it "should record missing key calls" do
    instance = described_class.new({})
    instance.foo.bar = false

    keys = instance.__internal_state["missing_key_calls"]
    keys.should be_kind_of(Set)
    keys.length.should == 1
    keys.include?("foo").should be
  end
end
