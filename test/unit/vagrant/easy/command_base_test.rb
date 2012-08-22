require File.expand_path("../../../base", __FILE__)

describe Vagrant::Easy::CommandBase do
  let(:klass) { Class.new(described_class) }

  it "should raise an error if instantiated directly" do
    expect { described_class.new(nil, nil) }.to raise_error(RuntimeError)
  end

  it "should raise an error if command/runner are not set" do
    expect { klass.new(nil, nil) }.to raise_error(ArgumentError)
  end

  it "should inherit the configured name" do
    klass.configure("name") {}

    instance = klass.new(nil, nil)
    instance.command.should == "name"
  end
end
