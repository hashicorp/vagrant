# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::NetworkScriptsDir" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
  end

  let(:is_legacy) { false }
  let(:communicator) { double("communicator") }
  let(:machine) { double("machine", communicate: communicator) }

  before do
    allow(communicator).to receive(:test).with("test -d /etc/sysconfig/network-scripts").and_return(is_legacy)
  end

  describe ".network_scripts_dir" do
    let(:cap) { caps.get(:network_scripts_dir) }

    let(:name) { "banana-rama.example.com" }

    it "is /etc/NetworkManager/system-connections" do
      expect(cap.network_scripts_dir(machine)).to eq("/etc/NetworkManager/system-connections")
    end

    context 'when version is legacy' do
      let(:is_legacy) { true }

      it "is /etc/sysconfig/network-scripts" do
        expect(cap.network_scripts_dir(machine)).to eq("/etc/sysconfig/network-scripts")
      end
    end
  end
end
