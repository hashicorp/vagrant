# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_6_1 do
  include_context "virtualbox"

  let(:vbox_version) { "6.1.0" }

  subject { VagrantPlugins::ProviderVirtualBox::Driver::Version_6_1.new(uuid) }

  it_behaves_like "a version 5.x virtualbox driver"
  it_behaves_like "a version 6.x virtualbox driver"

  describe "#read_dhcp_servers" do
    before {
      expect(subprocess).to receive(:execute).
        with("VBoxManage", "list", "dhcpservers", an_instance_of(Hash)).
        and_return(subprocess_result(stdout: output))
    }

    context "with empty output" do
      let(:output) { "" }

      it "returns an empty list" do
        expect(subject.read_dhcp_servers).to eq([])
      end
    end

    context "with a single dhcp server" do
      let(:output) {
        <<-OUTPUT.gsub(/^ */, '')
          NetworkName:    HostInterfaceNetworking-vboxnet0
          Dhcpd IP:       192.168.56.100
          LowerIPAddress: 192.168.56.101
          UpperIPAddress: 192.168.56.254
          NetworkMask:    255.255.255.0
          Enabled:        Yes
          Global Configuration:
              minLeaseTime:     default
              defaultLeaseTime: default
              maxLeaseTime:     default
              Forced options:   None
              Suppressed opts.: None
                  1/legacy: 255.255.255.0
          Groups:               None
          Individual Configs:   None

        OUTPUT
      }


      it "returns a list with one entry describing that server" do
        expect(subject.read_dhcp_servers).to eq([{
          network_name: 'HostInterfaceNetworking-vboxnet0',
          network:      'vboxnet0',
          ip:           '192.168.56.100',
          netmask:      '255.255.255.0',
          lower:        '192.168.56.101',
          upper:        '192.168.56.254',
        }])
      end
    end

    context "with a multiple dhcp servers" do
      let(:output) {
        <<-OUTPUT.gsub(/^ */, '')
          NetworkName:    HostInterfaceNetworking-vboxnet0
          Dhcpd IP:       192.168.56.100
          LowerIPAddress: 192.168.56.101
          UpperIPAddress: 192.168.56.254
          NetworkMask:    255.255.255.0
          Enabled:        Yes
          Global Configuration:
              minLeaseTime:     default
              defaultLeaseTime: default
              maxLeaseTime:     default
              Forced options:   None
              Suppressed opts.: None
                  1/legacy: 255.255.255.0
          Groups:               None
          Individual Configs:   None

          NetworkName:    HostInterfaceNetworking-vboxnet5
          Dhcpd IP:       172.28.128.2
          LowerIPAddress: 172.28.128.3
          UpperIPAddress: 172.28.128.254
          NetworkMask:    255.255.255.0
          Enabled:        Yes
          Global Configuration:
              minLeaseTime:     default
              defaultLeaseTime: default
              maxLeaseTime:     default
              Forced options:   None
              Suppressed opts.: None
                  1/legacy: 255.255.255.0
          Groups:               None
          Individual Configs:   None
        OUTPUT
      }


      it "returns a list with one entry for each server" do
        expect(subject.read_dhcp_servers).to eq([{
          network_name: 'HostInterfaceNetworking-vboxnet0',
          network:      'vboxnet0',
          ip:           '192.168.56.100',
          netmask:      '255.255.255.0',
          lower:        '192.168.56.101',
          upper:        '192.168.56.254',
        },{
          network_name: 'HostInterfaceNetworking-vboxnet5',
          network:      'vboxnet5',
          ip:           '172.28.128.2',
          netmask:      '255.255.255.0',
          lower:        '172.28.128.3',
          upper:        '172.28.128.254',
        }])
      end
    end
  end
end
