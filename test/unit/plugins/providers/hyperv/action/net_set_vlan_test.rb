# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/net_set_vlan")

describe VagrantPlugins::HyperV::Action::NetSetVLan do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, provider_config: provider_config) }
  let(:provider_config){ double("provider_config", vlan_id: vlan_id) }
  let(:vlan_id){ "VID" }
  let(:subject){ described_class.new(app, env) }

  before do
    allow(driver).to receive(:net_set_vlan)
    allow(app).to receive(:call)
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  it "should call the driver to set the vlan id" do
    expect(driver).to receive(:net_set_vlan).with(vlan_id)
    subject.call(env)
  end

  context "with no vlan id provided" do
    let(:vlan_id){ nil }

    it "should not call driver to set the vlan id" do
      expect(driver).not_to receive(:net_set_vlan)
      subject.call(env)
    end
  end
end
