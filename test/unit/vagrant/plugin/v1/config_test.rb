require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Plugin::V1::Config do
  include_context "unit"

  let(:foo_class) do
    Class.new(described_class) do
      attr_accessor :one
      attr_accessor :two
    end
  end

  it "has an UNSET_VALUE constant" do
    value = described_class.const_get("UNSET_VALUE")
    expect(value).to be_kind_of Object
    expect(value).to eql(described_class.const_get("UNSET_VALUE"))
  end

  describe "merging" do
    it "should merge by default by simply copying each instance variable" do
      one = foo_class.new
      one.one = 2
      one.two = 1

      two = foo_class.new
      two.two = 5

      result = one.merge(two)
      expect(result.one).to eq(2)
      expect(result.two).to eq(5)
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
      expect(result.one).to eq(1)
      expect(result.two).to eq(2)
      expect(result.instance_variable_get(:@__bar)).to be_nil
    end
  end
end
