# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/check_enabled")

describe VagrantPlugins::HyperV::Action::CheckEnabled do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider) }
  let(:subject){ described_class.new(app, env) }

  it "should continue when Hyper-V is enabled" do
    expect(driver).to receive(:execute).and_return("result" => true)
    expect(app).to receive(:call)
    subject.call(env)
  end

  it "should raise error when Hyper-V is not enabled" do
    expect(driver).to receive(:execute).and_return("result" => false)
    expect(app).not_to receive(:call)
    expect{ subject.call(env) }.to raise_error(VagrantPlugins::HyperV::Errors::PowerShellFeaturesDisabled)
  end
end
