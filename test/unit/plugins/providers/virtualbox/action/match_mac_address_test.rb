# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Action::MatchMACAddress do
  let(:ui) { Vagrant::UI::Silent.new }
  let(:machine) { double("machine", config: config, provider: double("provider", driver: driver)) }
  let(:driver) { double("driver") }
  let(:env) {
    {machine: machine, ui: ui}
  }
  let(:app) { double("app") }
  let(:config) { double("config", vm: vm) }
  let(:vm) { double("vm", clone: clone, base_mac: base_mac) }
  let(:clone) { false }
  let(:base_mac) { "00:00:00:00:00:00" }

  let(:subject) { described_class.new(app, env) }

  before do
    allow(app).to receive(:call)
  end

  after { subject.call(env) }

  it "should set the mac address" do
    expect(driver).to receive(:set_mac_address).with(base_mac)
  end

  context "when clone is true" do
    let(:clone) { true }

    it "should not set mac address" do
      expect(driver).not_to receive(:set_mac_address)
    end
  end

  context "when base_mac is falsey" do
    let(:base_mac) { nil }

    it "should set mac address" do
      expect(driver).to receive(:set_mac_address).with(base_mac)
    end
  end
end
