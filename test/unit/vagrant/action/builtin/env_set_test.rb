require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::EnvSet do
  let(:app) { lambda { |env| } }
  let(:env) { {} }

  it "should set the new environment" do
    described_class.new(app, env, foo: :bar).call(env)

    expect(env[:foo]).to eq(:bar)
  end

  it "should call the next middleware" do
    callable = lambda { |env| env[:called] = env[:foo] }

    expect(env[:called]).to be_nil
    described_class.new(callable, env, foo: :yep).call(env)
    expect(env[:called]).to eq(:yep)
  end
end
