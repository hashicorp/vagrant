require "pathname"

require File.expand_path("../../base", __FILE__)

describe Vagrant::MachineState do
  include_context "unit"

  let(:id) { :some_state }
  let(:short) { "foo" }
  let(:long) { "I am a longer foo" }

  it "should give access to the id" do
    instance = described_class.new(id, short, long)
    expect(instance.id).to eq(id)
  end

  it "should give access to the short description" do
    instance = described_class.new(id, short, long)
    expect(instance.short_description).to eq(short)
  end

  it "should give access to the long description" do
    instance = described_class.new(id, short, long)
    expect(instance.long_description).to eq(long)
  end
end
