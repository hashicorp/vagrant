require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::Builtin::Trigger do
  let(:app) { lambda { |env| } }
  let(:env) { {machine: machine} }
  let(:machine) { nil }
  let(:triggers) { double("triggers") }
  let(:name) { "trigger-name" }
  let(:timing) { :before }
  let(:type) { :action }

  let(:subject) { described_class.
      new(app, env, name, triggers, timing, type) }

  before do
    allow(triggers).to receive(:fire)
    allow(app).to receive(:call)
  end


  it "should properly create a new instance" do
    expect(subject).to be_a(described_class)
  end

  it "should fire triggers" do
    expect(triggers).to receive(:fire)
    subject.call(env)
  end

  it "should fire triggers without machine name" do
    expect(triggers).to receive(:fire).with(name, timing, nil, type, anything)
    subject.call(env)
  end

  context "when machine is provided" do
    let(:machine) { double("machine", name: "machine-name") }

    it "should include machine name when firing triggers" do
      expect(triggers).to receive(:fire).with(name, timing, "machine-name", type, anything)
      subject.call(env)
    end
  end

  context "when timing is :before" do
    it "should not error" do
      expect { subject }.not_to raise_error
    end
  end

  context "when timing is :after" do
    it "should not error" do
      expect { subject }.not_to raise_error
    end
  end

  context "when timing is not :before or :after" do
    let(:timing) { :unknown }

    it "should raise error" do
      expect { subject }.to raise_error(ArgumentError)
    end
  end
end
