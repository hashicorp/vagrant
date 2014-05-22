require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Config::V1::Root do
  include_context "unit"

  it "should provide access to config objects" do
    foo_class = Class.new
    map       = { foo: foo_class }

    instance  = described_class.new(map)
    foo       = instance.foo
    expect(foo).to be_kind_of(foo_class)
    expect(instance.foo).to eql(foo)
  end

  it "can be created with initial state" do
    instance = described_class.new({}, { foo: "bar" })
    expect(instance.foo).to eq("bar")
  end

  it "should return internal state" do
    map      = { "foo" => Object, "bar" => Object }
    instance = described_class.new(map)
    expect(instance.__internal_state).to eq({
      "config_map" => map,
      "keys"       => {},
      "missing_key_calls" => Set.new
    })
  end

  it "should record missing key calls" do
    instance = described_class.new({})
    instance.foo.bar = false

    keys = instance.__internal_state["missing_key_calls"]
    expect(keys).to be_kind_of(Set)
    expect(keys.length).to eq(1)
    expect(keys.include?("foo")).to be
  end
end
