require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Call do
  let(:app) { lambda { |env| } }
  let(:env) { {} }

  it "should yield the result to the block" do
    received = nil

    callable = lambda do |env|
      env[:result] = "value"
    end

    described_class.new(app, env, callable) do |result, builder|
      received = result
    end.call({})

    received.should == "value"
  end

  it "should give a nil result if no result is given" do
    received = 42
    callable = lambda { |env| }

    described_class.new(app, env, callable) do |result, builder|
      received = result
    end.call({})

    received.should be_nil
  end

  it "should call the callable with the original environment" do
    received = nil
    callable = lambda { |env| received = env[:foo] }

    described_class.new(app, env, callable) do |result, builder|
      # Nothing.
    end.call({ :foo => :bar })

    received.should == :bar
   end

  it "should call the next builder" do
    received = nil
    callable = lambda { |env| }
    next_step = lambda { |env| received = "value" }

    described_class.new(app, env, callable) do |result, builder|
      builder.use next_step
    end.call({})

    received.should == "value"
  end

  it "should call the next builder with the original environment" do
    received = nil
    callable = lambda { |env| }
    next_step = lambda { |env| received = env[:foo] }

    described_class.new(app, env, callable) do |result, builder|
      builder.use next_step
    end.call({ :foo => :bar })

    received.should == :bar
  end
end
