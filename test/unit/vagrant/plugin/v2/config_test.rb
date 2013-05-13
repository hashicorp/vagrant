require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V2::Config do
  include_context "unit"

  let(:foo_class) do
    Class.new(described_class) do
      attr_accessor :one
      attr_accessor :two
    end
  end

  let(:unset_value) { described_class.const_get("UNSET_VALUE") }

  describe "merging" do
    it "should merge by default by simply copying each instance variable" do
      one = foo_class.new
      one.one = 2
      one.two = 1

      two = foo_class.new
      two.two = 5

      result = one.merge(two)
      result.one.should == 2
      result.two.should == 5
    end

    it "prefers any set value over an UNSET_VALUE" do
      one = foo_class.new
      one.one = 1
      one.two = 2

      two = foo_class.new
      two.one = unset_value
      two.two = 5

      result = one.merge(two)
      result.one.should == 1
      result.two.should == 5
    end

    it "doesn't merge values that start with a double underscore" do
      one = foo_class.new
      one.one = 1
      one.two = 1
      one.instance_variable_set(:@__bar, "one")

      two = foo_class.new
      two.two = 2
      two.instance_variable_set(:@__bar, "two")

      # Merge and verify
      result = one.merge(two)
      result.one.should == 1
      result.two.should == 2
      result.instance_variable_get(:@__bar).should be_nil
    end
  end
end
