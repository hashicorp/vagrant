require File.expand_path("../../../base", __FILE__)

describe Vagrant::Downloaders::Base do
  let(:ui) { double("ui") }
  let(:instance) { described_class.new(ui) }

  it "should not match anything by default" do
    described_class.match?("foo").should_not be
  end

  it "should implement `prepare`" do
    instance.prepare("foo").should be_nil
  end

  it "should implement `download!`" do
    instance.download!("foo", "bar").should be_nil
  end
end
