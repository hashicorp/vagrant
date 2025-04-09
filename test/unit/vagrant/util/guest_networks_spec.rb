# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/guest_networks"

describe Vagrant::Util::GuestNetworks::Linux do
  include_context "unit"

  subject { Class.new { extend Vagrant::Util::GuestNetworks::Linux } }

  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:config) { double("config", vm: vm) }
  let(:guest) { double("guest") }
  let(:machine) { double("machine", guest: guest, config: config) }
  let(:networks){ [[:public_network, network_1], [:private_network, network_2]] }
  let(:vm){ double("vm", networks: networks) }
  let(:interfaces) { ["eth1", "eth2", "eth3"] }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(guest).to receive(:capability).with(:network_interfaces).and_return(interfaces)
  end

  after do
    comm.verify_expectations!
  end

  let(:network_1) do
    {
      interface: 0,
      type: "dhcp",
    }
  end

  let(:network_2) do
    {
      interface: 1,
      type: "static",
      ip: "33.33.33.10",
      netmask: "255.255.0.0",
      gateway: "33.33.0.1",
    }
  end

  let(:network_3) do
    {
      interface: 2,
      type: "static",
      ip: "33.33.33.11",
      netmask: "255.255.0.0",
      gateway: "33.33.0.1",
    }
  end

  it "should fetch mac address for devices" do
    subject.configure_network_manager(machine, [network_1, network_2, network_3])

    expect(comm.received_commands).to include(%r{/net/eth1/address})
    expect(comm.received_commands).to include(%r{/net/eth2/address})
    expect(comm.received_commands).to include(%r{/net/eth3/address})
  end

  it "should change ownership of files" do
    subject.configure_network_manager(machine, [network_1, network_2, network_3])

    expect(comm.received_commands).to include(%r{chown root:root '/tmp/vagrant.*eth1.*'})
    expect(comm.received_commands).to include(%r{chown root:root '/tmp/vagrant.*eth2.*'})
    expect(comm.received_commands).to include(%r{chown root:root '/tmp/vagrant.*eth3.*'})
  end

  it "should change mode of files" do
    subject.configure_network_manager(machine, [network_1, network_2, network_3])

    expect(comm.received_commands).to include(%r{chmod 0600 '/tmp/vagrant.*eth1.*'})
    expect(comm.received_commands).to include(%r{chmod 0600 '/tmp/vagrant.*eth2.*'})
    expect(comm.received_commands).to include(%r{chmod 0600 '/tmp/vagrant.*eth3.*'})
  end

  it "should move configuration files" do
    subject.configure_network_manager(machine, [network_1, network_2, network_3])

    expect(comm.received_commands).to include(%r{mv '/tmp/vagrant.*eth1.*' '/etc/NetworkManager/system-connections/eth1.nmconnection'})
    expect(comm.received_commands).to include(%r{mv '/tmp/vagrant.*eth2.*' '/etc/NetworkManager/system-connections/eth2.nmconnection'})
    expect(comm.received_commands).to include(%r{mv '/tmp/vagrant.*eth3.*' '/etc/NetworkManager/system-connections/eth3.nmconnection'})
  end

  it "should move configuration files" do
    subject.configure_network_manager(machine, [network_1, network_2, network_3])

    expect(comm.received_commands).to include(%r{mv '/tmp/vagrant.*eth1.*' '/etc/NetworkManager/system-connections/eth1.nmconnection'})
    expect(comm.received_commands).to include(%r{mv '/tmp/vagrant.*eth2.*' '/etc/NetworkManager/system-connections/eth2.nmconnection'})
    expect(comm.received_commands).to include(%r{mv '/tmp/vagrant.*eth3.*' '/etc/NetworkManager/system-connections/eth3.nmconnection'})
  end

  it "should move load new configuration files" do
    subject.configure_network_manager(machine, [network_1, network_2, network_3])

    expect(comm.received_commands).to include("nmcli c load '/etc/NetworkManager/system-connections/eth1.nmconnection'")
    expect(comm.received_commands).to include("nmcli c load '/etc/NetworkManager/system-connections/eth2.nmconnection'")
    expect(comm.received_commands).to include("nmcli c load '/etc/NetworkManager/system-connections/eth3.nmconnection'")
  end

  it "should connect new devices" do
    subject.configure_network_manager(machine, [network_1, network_2, network_3])

    expect(comm.received_commands).to include("nmcli d connect 'eth1'")
    expect(comm.received_commands).to include("nmcli d connect 'eth2'")
    expect(comm.received_commands).to include("nmcli d connect 'eth3'")
  end

  context "network configuration file" do
    let(:networks){ [[:public_network, network_1], [:private_network, network_2], [:private_network, network_3]] }

    let(:tempfile) { double("tempfile") }

    before do
      allow(tempfile).to receive(:binmode)
      allow(tempfile).to receive(:write)
      allow(tempfile).to receive(:fsync)
      allow(tempfile).to receive(:close)
      allow(tempfile).to receive(:path)
      allow(Tempfile).to receive(:open).and_yield(tempfile)
    end

    it "should generate two configuration files" do
      expect(Tempfile).to receive(:open).twice
      subject.configure_network_manager(machine, [network_1, network_2])
    end

    it "should generate three configuration files" do
      expect(Tempfile).to receive(:open).thrice
      subject.configure_network_manager(machine, [network_1, network_2, network_3])
    end

    it "should generate configuration with network_2 IP address" do
      expect(tempfile).to receive(:write).with(/#{network_2[:ip]}/)
      subject.configure_network_manager(machine, [network_1, network_2, network_3])
    end

    it "should generate configuration with network_3 IP address" do
      expect(tempfile).to receive(:write).with(/#{network_3[:ip]}/)
      subject.configure_network_manager(machine, [network_1, network_2, network_3])
    end
  end
end
