require "pathname"
require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::IsState do
  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine } }
  let(:machine) do
    double("machine").tap do |machine|
      allow(machine).to receive(:state).and_return(state)
    end
  end

  let(:state) { double("state") }

  describe "#call" do
    it "sets result to false if is proper state" do
      state.stub(id: :foo)

      subject = described_class.new(app, env, :bar)

      expect(app).to receive(:call).with(env)

      subject.call(env)
      expect(env[:result]).to be_false
    end

    it "sets result to true if is proper state" do
      state.stub(id: :foo)

      subject = described_class.new(app, env, :foo)

      expect(app).to receive(:call).with(env)

      subject.call(env)
      expect(env[:result]).to be_true
    end

    it "inverts the result if specified" do
      state.stub(id: :foo)

      subject = described_class.new(app, env, :foo, invert: true)

      expect(app).to receive(:call).with(env)

      subject.call(env)
      expect(env[:result]).to be_false
    end
  end
end
