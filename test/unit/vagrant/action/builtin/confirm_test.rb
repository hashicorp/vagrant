require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Confirm do
  let(:app) { lambda { |env| } }
  let(:env) { { ui: double("ui") } }
  let(:message) { "foo" }

  ["y", "Y"].each do |valid|
    it "should set the result to true if '#{valid}' is given" do
      expect(env[:ui]).to receive(:ask).with(message).and_return(valid)
      described_class.new(app, env, message).call(env)
      expect(env[:result]).to be
    end
  end

  it "should set the result to true if force matches" do
    force_key = :tubes
    env[force_key] = true
    described_class.new(app, env, message, force_key).call(env)
    expect(env[:result]).to be
  end

  it "should ask if force is not true" do
    force_key = :tubes
    env[force_key] = false
    expect(env[:ui]).to receive(:ask).with(message).and_return("nope")
    described_class.new(app, env, message).call(env)
    expect(env[:result]).not_to be
  end

  it "should set result to false if anything else is given" do
    expect(env[:ui]).to receive(:ask).with(message).and_return("nope")
    described_class.new(app, env, message).call(env)
    expect(env[:result]).not_to be
  end

  it "should ask multiple times if an allowed set is given and response isn't in that set" do
    times = 0
    allow(env[:ui]).to receive(:ask) do |arg|
      expect(arg).to eql(message)
      times += 1

      if times <= 3
        "nope"
      else
        "y"
      end
    end
    described_class.new(app, env, message, allowed: ["y", "N"]).call(env)
    expect(env[:result]).to be(true)
    expect(times).to eq(4)
  end
end
