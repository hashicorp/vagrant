require File.expand_path("../../../base", __FILE__)

describe Vagrant::Config::Base do
  include_context "unit"

  let(:foo_class) do
    Class.new(described_class) do
      attr_accessor :one
      attr_accessor :two
    end
  end

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
end
