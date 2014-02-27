require "pathname"
require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Message do
  let(:app) { lambda { |env| } }
  let(:env) { { :ui => ui } }

  let(:ui)  { double("ui") }

  describe "#call" do
    it "outputs the given message" do
      subject = described_class.new(app, env, "foo")

      ui.should_receive(:output).with("foo")
      app.should_receive(:call).with(env)

      subject.call(env)
    end
  end
end
