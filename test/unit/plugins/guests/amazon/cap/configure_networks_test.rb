# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../base"

describe "VagrantPlugins::GuestAmazon::Cap::ConfigureNetworks" do
  let(:caps) do
    VagrantPlugins::GuestAmazon::Plugin
      .components
      .guest_capabilities[:amazon]
  end

  let(:machine) { double("machine", communicate: communicator) }
  let(:communicator) { double("communicator") }
  let(:networks) { double("networks") }

  describe ".configure_networks" do
    let(:cap) { caps.get(:configure_networks) }
    before do
      allow(cap).to receive(:systemd_networkd?).
        with(communicator).and_return(is_networkd)
    end

    context "when guest is using networkd" do
      let(:is_networkd) { true  }

      it "should call the debian capability" do
        expect(VagrantPlugins::GuestDebian::Cap::ConfigureNetworks).
          to receive(:configure_networks).with(machine, networks)

        cap.configure_networks(machine, networks)
      end
    end

    context "when guest is not using networkd" do
      let(:is_networkd) { false }

      it "should call the redhat capability" do
        expect(VagrantPlugins::GuestRedHat::Cap::ConfigureNetworks).
          to receive(:configure_networks).with(machine, networks)

        cap.configure_networks(machine, networks)
      end
    end
  end
end
