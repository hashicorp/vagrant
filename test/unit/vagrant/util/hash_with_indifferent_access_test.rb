require File.expand_path("../../../base", __FILE__)

require "vagrant/util/hash_with_indifferent_access"

describe Vagrant::Util::HashWithIndifferentAccess do
  let(:instance) { described_class.new }

  it "is a Hash" do
    expect(instance).to be_kind_of(Hash)
  end

  it "allows indifferent access when setting with a string" do
    instance["foo"] = "bar"
    expect(instance[:foo]).to eq("bar")
  end

  it "allows indifferent access when setting with a symbol" do
    instance[:foo] = "bar"
    expect(instance["foo"]).to eq("bar")
  end

  it "allows indifferent key lookup" do
    instance["foo"] = "bar"
    expect(instance.key?(:foo)).to be
    expect(instance.key?(:foo)).to be
    expect(instance.include?(:foo)).to be
    expect(instance.member?(:foo)).to be
  end

  it "allows for defaults to be passed in via an initializer block" do
    instance = described_class.new do |h,k|
      h[k] = "foo"
    end

    expect(instance[:foo]).to eq("foo")
    expect(instance["bar"]).to eq("foo")
  end
end
