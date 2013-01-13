require File.expand_path("../../base", __FILE__)

describe Vagrant::Registry do
  let(:instance) { described_class.new }

  it "should return nil for nonexistent items" do
    instance.get("foo").should be_nil
  end

  it "should register a simple key/value" do
    instance.register("foo") { "value" }
    instance.get("foo").should == "value"
  end

  it "should register an item without calling the block yet" do
    expect do
      instance.register("foo") do
        raise Exception, "BOOM!"
      end
    end.to_not raise_error
  end

  it "should raise an error if no block is given" do
    expect { instance.register("foo") }.
      to raise_error(ArgumentError)
  end

  it "should call and return the result of a block when asking for the item" do
    object = Object.new
    instance.register("foo") do
      object
    end

    instance.get("foo").should eql(object)
  end

  it "should be able to get the item with []" do
    object = Object.new
    instance.register("foo") { object }

    instance["foo"].should eql(object)
  end

  it "should cache the result of the item so they can be modified" do
    # Make the proc generate a NEW array each time
    instance.register("foo") { [] }

    # Test that modifying the result modifies the actual cached
    # value. This verifies we're caching.
    instance.get("foo").should == []
    instance.get("foo") << "value"
    instance.get("foo").should == ["value"]
  end

  it "should be able to check if a key exists" do
    instance.register("foo") { "bar" }
    instance.should have_key("foo")
    instance.should_not have_key("bar")
  end

  it "should be enumerable" do
    instance.register("foo") { "foovalue" }
    instance.register("bar") { "barvalue" }

    keys   = []
    values = []
    instance.each do |key, value|
      keys << key
      values << value
    end

    keys.sort.should == ["bar", "foo"]
    values.sort.should == ["barvalue", "foovalue"]
  end

  it "should be able to convert to a hash" do
    instance.register("foo") { "foovalue" }
    instance.register("bar") { "barvalue" }

    result = instance.to_hash
    result.should be_a(Hash)
    result["foo"].should == "foovalue"
    result["bar"].should == "barvalue"
  end

  describe "merging" do
    it "should merge in another registry" do
      one = described_class.new
      two = described_class.new

      one.register("foo") { raise "BOOM!" }
      two.register("bar") { raise "BAM!" }

      three = one.merge(two)
      expect { three["foo"] }.to raise_error("BOOM!")
      expect { three["bar"] }.to raise_error("BAM!")
    end

    it "should NOT merge in the cache" do
      one = described_class.new
      two = described_class.new

      one.register("foo") { [] }
      one["foo"] << 1

      two.register("bar") { [] }
      two["bar"] << 2

      three = one.merge(two)
      three["foo"].should == []
      three["bar"].should == []
    end
  end

  describe "merge!" do
    it "should merge into self" do
      one = described_class.new
      two = described_class.new

      one.register("foo") { "foo" }
      two.register("bar") { "bar" }

      one.merge!(two)
      one["foo"].should == "foo"
      one["bar"].should == "bar"
    end
  end
end
