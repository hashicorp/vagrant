require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Call do
  let(:app) { lambda { |env| } }
  let(:env) { {} }

  it "should yield the env to the block" do
    received = nil

    callable = lambda do |env|
      env[:result] = "value"
    end

    described_class.new(app, env, callable) do |env, builder|
      received = env[:result]
    end.call({})

    received.should == "value"
  end

  it "should update the original env with any changes" do
    callable = lambda { |env| }
    next_step = lambda { |env| env[:inner] = true }

    described_class.new(app, env, callable) do |_env, builder|
      builder.use next_step
    end.call(env)

    env[:inner].should == true
  end

  it "should call the callable with the original environment" do
    received = nil
    callable = lambda { |env| received = env[:foo] }

    described_class.new(app, env, callable) do |_env, _builder|
      # Nothing.
    end.call({ :foo => :bar })

    received.should == :bar
   end

  it "should call the next builder" do
    received = nil
    callable = lambda { |env| }
    next_step = lambda { |env| received = "value" }

    described_class.new(app, env, callable) do |_env, builder|
      builder.use next_step
    end.call({})

    received.should == "value"
  end

  it "should call the next builder with the original environment" do
    received = nil
    callable = lambda { |env| }
    next_step = lambda { |env| received = env[:foo] }

    described_class.new(app, env, callable) do |_env, builder|
      builder.use next_step
    end.call({ :foo => :bar })

    received.should == :bar
  end

  it "should instantiate the callable with the extra args" do
    env = {}

    callable = Class.new do
      def initialize(app, env, arg)
        env[:arg] = arg
      end

      def call(env); end
    end

    result = nil
    instance = described_class.new(app, env, callable, :foo) do |inner_env, _builder|
      result = inner_env[:arg]
    end
    instance.call(env)

    result.should == :foo
  end

  it "should call the recover method for the sequence in an error" do
    # Basic variables
    callable = lambda { |env| }

    # Build the steps for the test
    basic_step = Class.new do
      def initialize(app, env)
        @app = app
        @env = env
      end

      def call(env)
        @app.call(env)
      end
    end

    step_a = Class.new(basic_step) do
      def call(env)
        env[:steps] << :call_A
        super
      end

      def recover(env)
        env[:steps] << :recover_A
      end
    end

    step_b = Class.new(basic_step) do
      def call(env)
        env[:steps] << :call_B
        super
      end

      def recover(env)
        env[:steps] << :recover_B
      end
    end

    instance = described_class.new(app, env, callable) do |_env, builder|
      builder.use step_a
      builder.use step_b
    end

    env[:steps] = []
    instance.call(env)
    instance.recover(env)

    env[:steps].should == [:call_A, :call_B, :recover_B, :recover_A]
  end

  it "should recover even if it failed in the callable" do
    callable = lambda { |env| raise "error" }

    instance = described_class.new(app, env, callable) { |_env, _builder| }
    instance.call(env) rescue nil
    expect { instance.recover(env) }.
      to_not raise_error
  end
end
