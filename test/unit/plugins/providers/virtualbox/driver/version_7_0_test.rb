# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "stringio"
require_relative "../base"

describe VagrantPlugins::ProviderVirtualBox::Driver::Version_7_0 do
  include_context "virtualbox"

  let(:vbox_version) { "7.0.0" }

  subject { VagrantPlugins::ProviderVirtualBox::Driver::Version_7_0.new(uuid) }

  it_behaves_like "a version 5.x virtualbox driver"
  it_behaves_like "a version 6.x virtualbox driver"

  describe "#read_forwarded_ports" do
    let(:uuid) { "MACHINE-UUID" }
    let(:cfg_path) { "MACHINE_CONFIG_PATH" }
    let(:vm_info) {
%(name="vagrant-test_default_1665781960041_56631"
Encryption:     disabled
groups="/"
ostype="Ubuntu (64-bit)"
UUID="#{uuid}"
CfgFile="#{cfg_path}"
SnapFldr="/VirtualBox VMs/vagrant-test_default_1665781960041_56631/Snapshots"
LogFldr="/VirtualBox VMs/vagrant-test_default_1665781960041_56631/Logs"
memory=1024)
    }
    let(:config_file) {
      StringIO.new(VBOX_VMCONFIG_FILE)
    }

    before do
      allow_any_instance_of(VagrantPlugins::ProviderVirtualBox::Driver::Meta).to receive(:version).and_return(vbox_version)
    end

    describe "VirtualBox version 7.0.0" do
      let(:vbox_version) { "7.0.0" }

      before do
        allow(subject).to receive(:execute).with("showvminfo", uuid, any_args).and_return(vm_info)
        allow(File).to receive(:open).with(cfg_path, "r").and_yield(config_file)
      end

      it "should return two port forward values" do
        expect(subject.read_forwarded_ports.size).to eq(2)
      end

      it "should have port forwards on slot one" do
        subject.read_forwarded_ports.each do |fwd|
          expect(fwd.first).to eq(1)
        end
      end

      it "should include host ip for ssh forward" do
        fwd = subject.read_forwarded_ports.detect { |f| f[1] == "ssh" }
        expect(fwd).not_to be_nil
        expect(fwd.last).to eq("127.0.0.1")
      end

      describe "when config file cannot be determine" do
        let(:vm_info) { %(name="vagrant-test_default_1665781960041_56631") }

        it "should raise a custom error" do
          expect(File).not_to receive(:open).with(cfg_path, "r")

          expect { subject.read_forwarded_ports }.to raise_error(Vagrant::Errors::VirtualBoxConfigNotFound)
        end
      end
    end

    describe "VirtualBox version greater than 7.0.0" do
      let(:vbox_version) { "7.0.1" }

      before do
        allow(subject).to receive(:execute).with("showvminfo", uuid, any_args).and_return(vm_info)
      end

      it "should not read configuration file" do
        expect(File).not_to receive(:open).with(cfg_path, "r")
        subject.read_forwarded_ports
      end
    end

  end

  describe "#use_host_only_nets?" do
    context "when platform is darwin" do
      before do
        allow(Vagrant::Util::Platform).to receive(:darwin?).and_return(true)
      end

      context "when virtualbox version is less than 7" do
        before do
          allow_any_instance_of(VagrantPlugins::ProviderVirtualBox::Driver::Meta).
            to receive(:version).and_return("6.0.28")
        end

        it "should return false" do
          expect(subject.send(:use_host_only_nets?)).to be(false)
        end
      end

      context "when virtualbox version is greater than 7" do
        before do
          allow_any_instance_of(VagrantPlugins::ProviderVirtualBox::Driver::Meta).
            to receive(:version).and_return("7.0.2")
        end

        it "should return true" do
          expect(subject.send(:use_host_only_nets?)).to be(true)
        end
      end

      context "when virtualbox version is equal to 7" do
        before do
          allow_any_instance_of(VagrantPlugins::ProviderVirtualBox::Driver::Meta).
            to receive(:version).and_return("7.0.0")
        end

        it "should return true" do
          expect(subject.send(:use_host_only_nets?)).to be(true)
        end
      end
    end

    context "when platform is not darwin" do
      before do
        allow(Vagrant::Util::Platform).to receive(:darwin?).and_return(false)
      end

      context "when virtualbox version is less than 7" do
        before do
          allow_any_instance_of(VagrantPlugins::ProviderVirtualBox::Driver::Meta).
            to receive(:version).and_return("6.0.28")
        end

        it "should return false" do
          expect(subject.send(:use_host_only_nets?)).to be(false)
        end
      end

      context "when virtualbox version is greater than 7" do
        before do
          allow_any_instance_of(VagrantPlugins::ProviderVirtualBox::Driver::Meta).
            to receive(:version).and_return("7.0.2")
        end

        it "should return false" do
          expect(subject.send(:use_host_only_nets?)).to be(false)
        end
      end

      context "when virtualbox version is equal to 7" do
        before do
          allow_any_instance_of(VagrantPlugins::ProviderVirtualBox::Driver::Meta).
            to receive(:version).and_return("7.0.0")
        end

        it "should return false" do
          expect(subject.send(:use_host_only_nets?)).to be(false)
        end
      end
    end
  end

  describe "#read_bridged_interfaces" do
    let(:bridgedifs) { VBOX_BRIDGEDIFS }

    before do
      allow(subject).to receive(:execute).and_call_original
      expect(subject).
        to receive(:execute).
             with("list", "bridgedifs").
             and_return(bridgedifs)
    end

    context "when hostonlynets are not enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
      end

      it "should return all interfaces in list" do
        expect(subject.read_bridged_interfaces.size).to eq(5)
      end

      it "should not read host only networks" do
        expect(subject).not_to receive(:read_host_only_networks)
        subject.read_bridged_interfaces
      end
    end

    context "when hostonlynets are enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
      end

      it "should return all interfaces in list" do
        expect(subject).to receive(:read_host_only_networks).and_return([])
        expect(subject.read_bridged_interfaces.size).to eq(5)
      end

      context "when hostonly networks are defined" do
        before do
          expect(subject).
            to receive(:execute).
                 with("list", "hostonlynets", any_args).
                 and_return(VBOX_HOSTONLYNETS)
        end

        it "should not return all interfaces in list" do
          expect(subject.read_bridged_interfaces.size).to_not eq(5)
        end

        it "should not include hostonly network devices" do
          expect(
            subject.read_bridged_interfaces.any? { |int|
              int[:name].start_with?("bridge")
            }
          ).to be(false)
        end
      end
    end

    context "when address is empty" do
      let(:bridgedifs) { VBOX_BRIDGEDIFS.sub("0.0.0.0", "") }

      it "should not raise an error" do
        expect { subject.read_bridged_interfaces }.to_not raise_error
      end
    end
  end

  describe "#delete_unused_host_only_networks" do
    context "when hostonlynets are not enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
      end

      it "should remove host only interfaces" do
        expect(subject).to receive(:execute).with("list", "hostonlyifs", any_args).and_return("")
        expect(subject).to receive(:execute).with("list", "vms", any_args).and_return("")
        subject.delete_unused_host_only_networks
      end

      it "should not read host only networks" do
        expect(subject).to receive(:execute).with("list", "hostonlyifs", any_args).and_return("")
        expect(subject).to receive(:execute).with("list", "vms", any_args).and_return("")
        expect(subject).not_to receive(:read_host_only_networks)
        subject.delete_unused_host_only_networks
      end
    end

    context "when hostonlynets are enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
        allow(subject).to receive(:read_host_only_networks).and_return([])
        allow(subject).to receive(:execute).with("list", "vms", any_args).and_return("")
      end

      it "should not read host only interfaces" do
        expect(subject).not_to receive(:execute).with("list", "hostonlyifs", any_args)
        subject.delete_unused_host_only_networks
      end

      context "when no host only networks are defined" do
        before do
          expect(subject).to receive(:read_host_only_networks).and_return([])
        end

        it "should not list vms" do
          expect(subject).not_to receive(:execute).with("list", "vms", any_args)
          subject.delete_unused_host_only_networks
        end
      end

      context "when host only networks are defined" do
        before do
          expect(subject).
            to receive(:read_host_only_networks).
                 and_return([{name: "vagrantnet-vbox-1"}])

        end

        context "when no vms are using the network" do
          before do
            expect(subject).to receive(:execute).with("list", "vms", any_args).and_return("")
          end

          it "should delete the network" do
            expect(subject).
              to receive(:execute).
                   with("hostonlynet", "remove", "--name", "vagrantnet-vbox-1", any_args)
            subject.delete_unused_host_only_networks
          end
        end

        context "when vms are using the network" do
          before do
            expect(subject).
              to receive(:execute).
                   with("list", "vms", any_args).
                   and_return(%("VM_NAME" {VM_ID}))
            expect(subject).
              to receive(:execute).
                   with("showvminfo", "VM_ID", any_args).
                   and_return(%(hostonly-network="vagrantnet-vbox-1"))
          end

          it "should not delete the network" do
            expect(subject).not_to receive(:execute).with("hostonlynet", "remove", any_args)
            subject.delete_unused_host_only_networks
          end
        end
      end
    end
  end

  describe "#enable_adapters" do
    let(:adapters) {
      [{hostonly: "hostonlynetwork", adapter: 1},
       {bridge: "eth0", adapter: 2}]
    }

    before do
      allow(subject).to receive(:execute).with("modifyvm", any_args)
    end

    context "when hostonlynets are not enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
      end

      it "should only call modifyvm once" do
        expect(subject).to receive(:execute).with("modifyvm", any_args).once
        subject.enable_adapters(adapters)
      end

      it "should configure host only network using hostonlyadapter" do
        expect(subject).to receive(:execute) { |*args|
          expect(args.first).to eq("modifyvm")
          expect(args).to include("--hostonlyadapter1")
          true
        }
        subject.enable_adapters(adapters)
      end
    end

    context "when hostonlynets are enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
      end

      it "should call modifyvm twice" do
        expect(subject).to receive(:execute).with("modifyvm", any_args).twice
        subject.enable_adapters(adapters)
      end

      it "should configure host only network using hostonlynet" do
        expect(subject).to receive(:execute).once
        expect(subject).to receive(:execute) { |*args|
          expect(args.first).to eq("modifyvm")
          expect(args).to include("--host-only-net1")
          true
        }
        subject.enable_adapters(adapters)
      end
    end
  end

  describe "#create_host_only_network" do
      let(:options) {
        {
          adapter_ip: "127.0.0.1",
          netmask: "255.255.255.0"
        }
      }

    context "when hostonlynets are disabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
      end

      it "should create using hostonlyif" do
        expect(subject).
          to receive(:execute).
               with("hostonlyif", "create", any_args).
               and_return("Interface 'host_only' was successfully created")
        expect(subject).
          to receive(:execute).
               with("hostonlyif", "ipconfig", "host_only", any_args)
        subject.create_host_only_network(options)
      end
    end

    context "when hostonlynets are enabled" do
      let(:prefix) { described_class.const_get(:HOSTONLY_NAME_PREFIX) }
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
        allow(subject).to receive(:read_host_only_networks).and_return([])
      end

      it "should create using hostonlynet" do
        expect(subject).
          to receive(:execute).
               with("hostonlynet", "add", "--name", prefix + "1",
                    "--netmask", options[:netmask], "--lower-ip",
                    "127.0.0.0", "--upper-ip", "127.0.0.0", any_args)
        subject.create_host_only_network(options)
      end

      context "when other host only networks exist" do
        before do
          expect(subject).
            to receive(:read_host_only_networks).
                 and_return(["custom", prefix + "1", prefix + "20"].map { |n| {name: n} })
        end

        it "should create network with incremented name" do
          expect(subject).
            to receive(:execute).
                 with("hostonlynet", "add", "--name", prefix + "21", any_args)
          subject.create_host_only_network(options)
        end
      end

      context "when dhcp information is included" do
        let(:options) {
          {
            type: :dhcp,
            dhcp_lower: "127.0.0.1",
            dhcp_upper: "127.0.1.200",
            netmask: "255.255.240.0"
          }
        }

        it "should set DHCP range" do
          expect(subject).
            to receive(:execute).
                 with("hostonlynet", "add", "--name", anything, "--netmask", options[:netmask],
                     "--lower-ip", options[:dhcp_lower], "--upper-ip", options[:dhcp_upper],
                     any_args)
          subject.create_host_only_network(options)
        end
      end
    end
  end

  describe "#reconfig_host_only" do
    let(:interface) { {name: "iname", ipv6: "VALUE"} }

    context "when hostonlynets are disabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
      end

      it "should apply ipv6 update" do
        expect(subject).to receive(:execute).with("hostonlyif", "ipconfig", interface[:name],
                                                 "--ipv6", interface[:ipv6], any_args)
        subject.reconfig_host_only(interface)
      end
    end

    context "when hostonlynets are enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
      end

      it "should do nothing" do
        expect(subject).not_to receive(:execute)
        subject.reconfig_host_only(interface)
      end
    end
  end

  describe "#remove_dhcp_server" do
    let(:dhcp_name) { double(:dhcp_name) }

    context "when hostonlynets are disabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
      end

      it "should remove the dhcp server" do
        expect(subject).to receive(:execute).with("dhcpserver", "remove", "--netname",
                                                  dhcp_name, any_args)
        subject.remove_dhcp_server(dhcp_name)
      end
    end

    context "when hostonlynets are enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
      end

      it "should do nothing" do
        expect(subject).not_to receive(:execute)
        subject.remove_dhcp_server(dhcp_name)
      end
    end
  end

  describe "#create_dhcp_server" do
    let(:network) { double("network") }
    let(:options) {
      {
        dhcp_ip: "127.0.0.1",
        netmask: "255.255.255.0",
        dhcp_lower: "127.0.0.2",
        dhcp_upper: "127.0.0.200"
      }
    }

    context "when hostonlynets is diabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
      end

      it "should create a dhcp server" do
        expect(subject).to receive(:execute).with("dhcpserver", "add", "--ifname", network,
                                                 "--ip", options[:dhcp_ip], any_args)
        subject.create_dhcp_server(network, options)
      end
    end

    context "when hostonlynets is enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
      end

      it "should do nothing" do
        expect(subject).not_to receive(:execute)
        subject.create_dhcp_server(network, options)
      end
    end
  end

  describe "#read_host_only_interfaces" do
    context "when hostonlynets is diabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
        allow(subject).to receive(:execute).and_return("")
      end

      it "should list hostonlyifs" do
        expect(subject).to receive(:execute).with("list", "hostonlyifs", any_args).and_return("")
        subject.read_host_only_interfaces
      end

      it "should not call read_host_only_networks" do
        expect(subject).not_to receive(:read_host_only_networks)
        subject.read_host_only_interfaces
      end
    end

    context "when hostonlynets is enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
        allow(subject).to receive(:execute).with("list", "hostonlynets", any_args).
                            and_return(VBOX_HOSTONLYNETS)
      end

      it "should call read_host_only_networks" do
        expect(subject).to receive(:read_host_only_networks).and_return([])
        subject.read_host_only_interfaces
      end

      it "should return defined networks" do
        expect(subject.read_host_only_interfaces.size).to eq(2)
      end

      it "should add compat information to network entries" do
        result = subject.read_host_only_interfaces
        expect(result.first[:netmask]).to eq(result.first[:networkmask])
        expect(result.first[:status]).to eq("Up")
      end

      it "should assign the address as the first in the subnet" do
        result = subject.read_host_only_interfaces
        expect(result.first[:ip]).to eq(IPAddr.new(result.first[:lowerip]).succ.to_s)
      end

      context "when dhcp range is set" do
        before do
          allow(subject).to receive(:execute).with("list", "hostonlynets", any_args).
                              and_return(VBOX_RANGE_HOSTONLYNETS)
        end

        it "should assign the address as the first in the dhcp range" do
          result = subject.read_host_only_interfaces
          expect(result.first[:ip]).to eq(result.first[:lowerip])
        end
      end
    end
  end

  describe "#read_host_only_networks" do
    before do
      allow(subject).to receive(:execute).with("list", "hostonlynets", any_args).
                          and_return(VBOX_HOSTONLYNETS)
    end

    it "should return defined networks" do
      expect(subject.read_host_only_networks.size).to eq(2)
    end

    it "should return expected network information" do
      result = subject.read_host_only_networks
      expect(result.first[:name]).to eq("vagrantnet-vbox1")
      expect(result.first[:lowerip]).to eq("192.168.61.0")
      expect(result.first[:networkmask]).to eq("255.255.255.0")
      expect(result.last[:name]).to eq("vagrantnet-vbox2")
      expect(result.last[:lowerip]).to eq("192.168.22.0")
      expect(result.last[:networkmask]).to eq("255.255.255.0")
    end
  end

  describe "#read_network_interfaces" do
    before do
      allow(subject)
        .to receive(:execute).
              with("showvminfo", any_args).
              and_return(VBOX_GUEST_HOSTONLYVNETS_INFO)
    end

    context "when hostonlynets is disabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(false)
      end

      it "should return two interfaces" do
        valid_interfaces = subject.read_network_interfaces.find_all { |k, v|
          v[:type] != :none
        }
        expect(valid_interfaces.size).to eq(2)
      end

      it "should include a nat type" do
        expect(subject.read_network_interfaces.detect { |_, v| v[:type] == :nat }).to be
      end

      it "should include a hostonlynetwork type with no information" do
        expect(subject.read_network_interfaces[2]).to eq({type: :hostonlynetwork})
      end
    end

    context "when hostonlynets is enabled" do
      before do
        allow(subject).to receive(:use_host_only_nets?).and_return(true)
      end

      it "should return two interfaces" do
        valid_interfaces = subject.read_network_interfaces.find_all { |k, v|
          v[:type] != :none
        }
        expect(valid_interfaces.size).to eq(2)
      end

      it "should include a nat type" do
        expect(subject.read_network_interfaces.detect { |_, v| v[:type] == :nat }).to be
      end

      it "should include a hostonly type" do
        expect(subject.read_network_interfaces.detect { |_, v| v[:type] == :hostonly }).to be
      end

      it "should not include a hostonlynetwork type" do
        expect(subject.read_network_interfaces.detect { |_, v|
                 v[:type] == :hostonlynetwork
               }).to_not be
      end

      it "should include the hostonly network name" do
        hostonly = subject.read_network_interfaces.values.detect { |v|
          v[:type] == :hostonly
        }
        expect(hostonly).to be
        expect(hostonly[:hostonly]).to eq("vagrantnet-vbox1")
      end
    end
  end
end

VBOX_VMCONFIG_FILE=%(<?xml version="1.0"?>
<VirtualBox xmlns="http://www.virtualbox.org/" version="1.19-linux">
  <Machine uuid="{623842dc-0947-4143-aa4e-7d180c5eb348}" name="vagrant-test_default_1665781960041_56631" OSType="Ubuntu_64" snapshotFolder="Snapshots">
    <Snapshot uuid="{467622d6-f25b-4aaa-94dd-e3e949efca0f}" name="Snapshot 1" timeStamp="2023-01-12T18:28:25Z">
      <Hardware>
        <Network>
          <Adapter slot="0" enabled="true" MACAddress="080027BB1475" type="82540EM">
            <NAT localhost-reachable="true">
              <DNS use-proxy="true"/>
              <Forwarding name="ssh" proto="1" hostip="127.0.0.1" hostport="2222" guestport="22"/>
            </NAT>
          </Adapter>
          <Adapter slot="1" enabled="true" MACAddress="080027DD5ADF" type="82540EM">
            <DisabledModes>
              <InternalNetwork name="intnet"/>
              <NATNetwork name="NatNetwork"/>
            </DisabledModes>
            <HostOnlyInterface name="vboxnet0"/>
          </Adapter>
        </Network>
      </Hardware>
    </Snapshot>
    <Hardware>
      <Network>
        <Adapter slot="0" enabled="true" MACAddress="080027BB1475" type="82540EM">
          <NAT localhost-reachable="true">
            <DNS use-proxy="true"/>
            <Forwarding name="ssh" proto="1" hostip="127.0.0.1" hostport="2222" guestport="22"/>
            <Forwarding name="tcp7700" proto="1" hostport="7700" guestport="80"/>
          </NAT>
        </Adapter>
        <Adapter slot="1" enabled="true" MACAddress="080027DD5ADF" type="82540EM">
          <DisabledModes>
            <InternalNetwork name="intnet"/>
            <NATNetwork name="NatNetwork"/>
          </DisabledModes>
          <HostOnlyInterface name="vboxnet0"/>
        </Adapter>
      </Network>
    </Hardware>
  </Machine>
</VirtualBox>)


VBOX_BRIDGEDIFS=%(Name:            en1: Wi-Fi (AirPort)
GUID:            00000000-0000-0000-0000-000000000001
DHCP:            Disabled
IPAddress:       10.0.0.49
NetworkMask:     255.255.255.0
IPV6Address:
IPV6NetworkMaskPrefixLength: 0
HardwareAddress: xx:xx:xx:xx:xx:01
MediumType:      Ethernet
Wireless:        Yes
Status:          Up
VBoxNetworkName: HostInterfaceNetworking-en1

Name:            en0: Ethernet
GUID:            00000000-0000-0000-0000-000000000002
DHCP:            Disabled
IPAddress:       0.0.0.0
NetworkMask:     0.0.0.0
IPV6Address:
IPV6NetworkMaskPrefixLength: 0
HardwareAddress: xx:xx:xx:xx:xx:02
MediumType:      Ethernet
Wireless:        No
Status:          Up
VBoxNetworkName: HostInterfaceNetworking-en0

Name:            bridge100
GUID:            00000000-0000-0000-0000-000000000003
DHCP:            Disabled
IPAddress:       192.168.61.1
NetworkMask:     255.255.255.0
IPV6Address:
IPV6NetworkMaskPrefixLength: 0
HardwareAddress: xx:xx:xx:xx:xx:03
MediumType:      Ethernet
Wireless:        No
Status:          Up
VBoxNetworkName: HostInterfaceNetworking-bridge100

Name:            en2: Thunderbolt 1
GUID:            00000000-0000-0000-0000-000000000004
DHCP:            Disabled
IPAddress:       0.0.0.0
NetworkMask:     0.0.0.0
IPV6Address:
IPV6NetworkMaskPrefixLength: 0
HardwareAddress: xx:xx:xx:xx:xx:04
MediumType:      Ethernet
Wireless:        No
Status:          Up
VBoxNetworkName: HostInterfaceNetworking-en2

Name:            bridge101
GUID:            00000000-0000-0000-0000-000000000005
DHCP:            Disabled
IPAddress:       192.168.22.1
NetworkMask:     255.255.255.0
IPV6Address:
IPV6NetworkMaskPrefixLength: 0
HardwareAddress: xx:xx:xx:xx:xx:05
MediumType:      Ethernet
Wireless:        No
Status:          Up
VBoxNetworkName: HostInterfaceNetworking-bridge101)

VBOX_HOSTONLYNETS=%(Name:            vagrantnet-vbox1
GUID:            10000000-0000-0000-0000-000000000000

State:           Enabled
NetworkMask:     255.255.255.0
LowerIP:         192.168.61.0
UpperIP:         192.168.61.0
VBoxNetworkName: hostonly-vagrantnet-vbox1

Name:            vagrantnet-vbox2
GUID:            20000000-0000-0000-0000-000000000000

State:           Enabled
NetworkMask:     255.255.255.0
LowerIP:         192.168.22.0
UpperIP:         192.168.22.0
VBoxNetworkName: hostonly-vagrantnet-vbox2)

VBOX_HOSTONLYNETS=%(Name:            vagrantnet-vbox1
GUID:            10000000-0000-0000-0000-000000000000

State:           Enabled
NetworkMask:     255.255.255.0
LowerIP:         192.168.61.0
UpperIP:         192.168.61.0
VBoxNetworkName: hostonly-vagrantnet-vbox1

Name:            vagrantnet-vbox2
GUID:            20000000-0000-0000-0000-000000000000

State:           Enabled
NetworkMask:     255.255.255.0
LowerIP:         192.168.22.0
UpperIP:         192.168.22.0
VBoxNetworkName: hostonly-vagrantnet-vbox2)

VBOX_RANGE_HOSTONLYNETS=%(Name:            vagrantnet-vbox1
GUID:            10000000-0000-0000-0000-000000000000

State:           Enabled
NetworkMask:     255.255.255.0
LowerIP:         192.168.61.10
UpperIP:         192.168.61.100
VBoxNetworkName: hostonly-vagrantnet-vbox1

Name:            vagrantnet-vbox2
GUID:            20000000-0000-0000-0000-000000000000

State:           Enabled
NetworkMask:     255.255.255.0
LowerIP:         192.168.22.0
UpperIP:         192.168.22.0
VBoxNetworkName: hostonly-vagrantnet-vbox2)

VBOX_GUEST_HOSTONLYVNETS_INFO=%(
natnet1="nat"
macaddress1="080027BB1475"
cableconnected1="on"
nic1="nat"
nictype1="82540EM"
nicspeed1="0"
mtu="0"
sockSnd="64"
sockRcv="64"
tcpWndSnd="64"
tcpWndRcv="64"
Forwarding(0)="ssh,tcp,127.0.0.1,2222,,22"
hostonly-network2="vagrantnet-vbox1"
macaddress2="080027FBC15B"
cableconnected2="on"
nic2="hostonlynetwork"
nictype2="82540EM"
nicspeed2="0"
nic3="none"
nic4="none"
nic5="none"
nic6="none"
nic7="none"
nic8="none"
)
