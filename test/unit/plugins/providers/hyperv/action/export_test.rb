# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/export")

describe VagrantPlugins::HyperV::Action::Export do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, state: state) }
  let(:state){ double("state", id: machine_state) }
  let(:machine_state){ :off }

  let(:subject){ described_class.new(app, env) }

  before do
    allow(app).to receive(:call)
    allow(driver).to receive(:export)
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  it "should call the driver to perform the export" do
    expect(driver).to receive(:export)
    subject.call(env)
  end

  context "with invalid machine state" do
    let(:machine_state){ :on }

    it "should raise an error" do
      expect{ subject.call(env) }.to raise_error(Vagrant::Errors::VMPowerOffToPackage)
    end
  end
end
