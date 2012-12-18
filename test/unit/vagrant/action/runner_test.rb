require File.expand_path("../../../base", __FILE__)

describe Vagrant::Action::Runner do
  let(:instance) { described_class.new }

  it "should raise an error if an invalid callable is given" do
    expect { instance.run(7) }.to raise_error(ArgumentError, /must be a callable/)
  end

  it "should be able to use a Proc as a callable" do
    callable = Proc.new { raise Exception, "BOOM" }
    expect { instance.run(callable) }.to raise_error(Exception, "BOOM")
  end

  it "should be able to use a Class as a callable" do
    callable = Class.new do
      def initialize(app, env)
      end

      def call(env)
        raise Exception, "BOOM"
      end
    end

    expect { instance.run(callable) }.to raise_error(Exception, "BOOM")
  end

  it "should return the resulting environment" do
    callable = lambda do |env|
      env[:data] = "value"

      # Return nil so we can make sure it isn't using this return value
      nil
    end

    result = instance.run(callable)
    result[:data].should == "value"
  end

  it "should pass options into hash given to callable" do
    result = nil
    callable = lambda do |env|
      result = env["data"]
    end

    instance.run(callable, "data" => "foo")
    result.should == "foo"
  end

  it "should pass global options into the hash" do
    result = nil
    callable = lambda do |env|
      result = env["data"]
    end

    instance = described_class.new("data" => "bar")
    instance.run(callable)
    result.should == "bar"
  end

  it "should yield the block passed to the init method to get lazy loaded globals" do
    result = nil
    callable = lambda do |env|
      result = env["data"]
    end

    instance = described_class.new { { "data" => "bar" } }
    instance.run(callable)
    result.should == "bar"
  end
end
