# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/net_set_mac")

describe VagrantPlugins::HyperV::Action::NetSetMac do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, provider_config: provider_config) }
  let(:provider_config){ double("provider_config", mac: mac) }
  let(:mac){ "ADDRESS" }
  let(:subject){ described_class.new(app, env) }

  before do
    allow(driver).to receive(:net_set_mac)
    allow(app).to receive(:call)
  end

  it "should call the app on success" do
    expect(app).to receive(:call)
    subject.call(env)
  end

  it "should call the driver to set the MAC address" do
    expect(driver).to receive(:net_set_mac).with(mac)
    subject.call(env)
  end

  context "with no MAC address provided" do
    let(:mac){ nil }

    it "should not call driver to set the MAC address" do
      expect(driver).not_to receive(:net_set_mac)
      subject.call(env)
    end
  end
end
