require "pathname"
require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::IsEnvSet do
  let(:app) { lambda { |env| } }
  let(:env) { { } }

  describe "#call" do
    it "sets result to true if it is set" do
      env[:bar] = true

      subject = described_class.new(app, env, :bar)

      expect(app).to receive(:call).with(env)

      subject.call(env)
      expect(env[:result]).to be(true)
    end

    it "sets result to false if it isn't set" do
      subject = described_class.new(app, env, :bar)

      expect(app).to receive(:call).with(env)

      subject.call(env)
      expect(env[:result]).to be(false)
    end
  end
end
