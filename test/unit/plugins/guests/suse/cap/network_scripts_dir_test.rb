# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::NetworkScriptsDir" do
  let(:caps) do
    VagrantPlugins::GuestSUSE::Plugin
      .components
      .guest_capabilities[:suse]
  end

  let(:comm) { double("comm") }
  let(:machine) { double("machine", communicate: comm) }

  describe ".network_scripts_dir" do
    let(:cap) { caps.get(:network_scripts_dir) }

    context "when /etc/sysconfig/network exists" do
      before do
        allow(comm).to receive(:test).with("test -d /etc/sysconfig/network")
          .and_return(true)
      end

      it "returns /etc/sysconfig/network" do
        expect(cap.network_scripts_dir(machine)).to eq("/etc/sysconfig/network")
      end
    end

    context "when /etc/sysconfig/network does not exist" do
      before do
        allow(comm).to receive(:test).with("test -d /etc/sysconfig/network")
          .and_return(false)
      end

      it "returns /etc/NetworkManager/system-connections" do
        expect(cap.network_scripts_dir(machine)).to eq("/etc/NetworkManager/system-connections")
      end
    end
  end
end
