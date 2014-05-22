require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Call do
  let(:app) { lambda { |env| } }
  let(:env) { {} }

  def wrapper_proc(data)
    Class.new do
      def initialize(app, env)
        @app = app
      end

      define_method(:call) do |env|
        env[:data] << "#{data}_in"
        @app.call(env)
        env[:data] << "#{data}_out"
      end
    end
  end

  it "should yield the env to the block" do
    received = nil

    callable = lambda do |env|
      env[:result] = "value"
    end

    described_class.new(app, env, callable) do |env, builder|
      received = env[:result]
    end.call({})

    expect(received).to eq("value")
  end

  it "should update the original env with any changes" do
    callable = lambda { |env| }
    next_step = lambda { |env| env[:inner] = true }

    described_class.new(app, env, callable) do |_env, builder|
      builder.use next_step
    end.call(env)

    expect(env[:inner]).to eq(true)
  end

  it "should call the callable with the original environment" do
    received = nil
    callable = lambda { |env| received = env[:foo] }

    described_class.new(app, env, callable) do |_env, _builder|
      # Nothing.
    end.call({ foo: :bar })

    expect(received).to eq(:bar)
   end

  it "should call the next builder" do
    received = nil
    callable = lambda { |env| }
    next_step = lambda { |env| received = "value" }

    described_class.new(app, env, callable) do |_env, builder|
      builder.use next_step
    end.call({})

    expect(received).to eq("value")
  end

  it "should call the next builder with the original environment" do
    received = nil
    callable = lambda { |env| }
    next_step = lambda { |env| received = env[:foo] }

    described_class.new(app, env, callable) do |_env, builder|
      builder.use next_step
    end.call({ foo: :bar })

    expect(received).to eq(:bar)
  end

  it "should call the next builder inserted in our own stack" do
    callable = lambda { |env| }

    builder = Vagrant::Action::Builder.new.tap do |b|
      b.use wrapper_proc(1)
      b.use described_class, callable do |_env, b2|
        b2.use wrapper_proc(2)
      end
      b.use wrapper_proc(3)
    end

    env = { data: [] }
    builder.call(env)
    expect(env[:data]).to eq([
      "1_in", "2_in", "3_in", "3_out", "2_out", "1_out"])
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

    expect(result).to eq(:foo)
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

    expect(env[:steps]).to eq([:call_A, :call_B, :recover_B, :recover_A])
  end

  it "should recover even if it failed in the callable" do
    callable = lambda { |env| raise "error" }

    instance = described_class.new(app, env, callable) { |_env, _builder| }
    instance.call(env) rescue nil
    expect { instance.recover(env) }.
      to_not raise_error
  end
end
