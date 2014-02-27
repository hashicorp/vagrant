require "pathname"
require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::IsState do
  let(:app) { lambda { |env| } }
  let(:env) { { :machine => machine } }
  let(:machine) do
    double("machine").tap do |machine|
      machine.stub(:state).and_return(state)
    end
  end

  let(:state) { double("state") }

  describe "#call" do
    it "sets result to true if is proper state" do
      state.stub(id: :foo)

      subject = described_class.new(app, env, :foo)

      app.should_receive(:call).with(env)

      subject.call(env)
      expect(env[:result]).to be_true
    end
  end
end
