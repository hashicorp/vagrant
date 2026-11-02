# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/darwin/cap/configured_ip_addresses"

describe VagrantPlugins::HostDarwin::Cap::ConfiguredIPAddresses do

  let(:subject){ VagrantPlugins::HostDarwin::Cap::ConfiguredIPAddresses }
  let(:interfaces){ ["192.168.1.2"] }
  before{ allow(Socket).to receive(:getifaddrs).and_return(
    interfaces.map{|i| double(:socket, addr: Addrinfo.ip(i))}) }

  it "should get list of available addresses" do
    expect(subject.configured_ip_addresses(nil)).to eq(["192.168.1.2"])
  end

  context "with loopback address" do
    let(:interfaces){ ["192.168.1.2", "127.0.0.1"] }

    it "should not include loopback address" do
      expect(subject.configured_ip_addresses(nil)).not_to include(["127.0.0.1"])
    end
  end

  context "with IPv6 address" do
    let(:interfaces){ ["192.168.1.2", "2001:200:dff:fff1:216:3eff:feb1:44d7"] }

    it "should not include IPv6 address" do
      expect(subject.configured_ip_addresses(nil)).not_to include(["2001:200:dff:fff1:216:3eff:feb1:44d7"])
    end
  end
end
