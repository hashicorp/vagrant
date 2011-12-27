require File.expand_path("../../../base", __FILE__)

require "vagrant/util/hash_with_indifferent_access"

describe Vagrant::Util::HashWithIndifferentAccess do
  let(:instance) { described_class.new }

  it "is a Hash" do
    instance.should be_kind_of(Hash)
  end

  it "allows indifferent access when setting with a string" do
    instance["foo"] = "bar"
    instance[:foo].should == "bar"
  end

  it "allows indifferent access when setting with a symbol" do
    instance[:foo] = "bar"
    instance["foo"].should == "bar"
  end

  it "allows indifferent key lookup" do
    instance["foo"] = "bar"
    instance.key?(:foo).should be
    instance.has_key?(:foo).should be
    instance.include?(:foo).should be
    instance.member?(:foo).should be
  end

  it "allows for defaults to be passed in via an initializer block" do
    instance = described_class.new do |h,k|
      h[k] = "foo"
    end

    instance[:foo].should == "foo"
    instance["bar"].should == "foo"
  end
end
