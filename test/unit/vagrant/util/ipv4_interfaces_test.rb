# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/ipv4_interfaces"

describe Vagrant::Util::IPv4Interfaces do
  subject { described_class }

  describe "#ipv4_interfaces" do
    let(:name) { double("name") }
    let(:address) { double("address") }

    let(:ipv4_ifaddr) do
      double("ipv4_ifaddr").tap do |ifaddr|
        allow(ifaddr).to receive(:name).and_return(name)
        allow(ifaddr).to receive_message_chain(:addr, :ipv4?).and_return(true)
        allow(ifaddr).to receive_message_chain(:addr, :ip_address).and_return(address)
      end
    end

    let(:ipv6_ifaddr) do
      double("ipv6_ifaddr").tap do |ifaddr|
        allow(ifaddr).to receive(:name)
        allow(ifaddr).to receive_message_chain(:addr, :ipv4?).and_return(false)
      end
    end

    let(:ifaddrs) { [ ipv4_ifaddr, ipv6_ifaddr ] }

    before do
      allow(Socket).to receive(:getifaddrs).and_return(ifaddrs)
    end

    it "returns a list of IPv4 interfaces with their names and addresses" do
      expect(subject.ipv4_interfaces).to eq([ [name, address] ])
    end

    context "with nil interface address" do
      let(:nil_ifaddr) { double("nil_ifaddr", addr: nil ) }
      let(:ifaddrs) { [ ipv4_ifaddr, ipv6_ifaddr, nil_ifaddr ] }

      it "filters out nil addr info" do
        expect(subject.ipv4_interfaces).to eq([ [name, address] ])
      end
    end
  end
end

