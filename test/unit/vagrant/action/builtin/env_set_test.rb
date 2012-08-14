require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::EnvSet do
  let(:app) { lambda { |env| } }
  let(:env) { {} }

  it "should set the new environment" do
    described_class.new(app, env, :foo => :bar).call(env)

    env[:foo].should == :bar
  end

  it "should call the next middleware" do
    callable = lambda { |env| env[:called] = env[:foo] }

    env[:called].should be_nil
    described_class.new(callable, env, :foo => :yep).call(env)
    env[:called].should == :yep
  end
end
