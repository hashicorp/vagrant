# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

describe "VagrantPlugins::GuestCoreOS::Cap::ConfigureNetworks" do
  let(:described_class) do
    VagrantPlugins::GuestCoreOS::Plugin
      .components
      .guest_capabilities[:coreos]
      .get(:configure_networks)
  end

  let(:machine) { double("machine", config: config, guest: guest) }
  let(:guest) { double("guest") }
  let(:config) { double("config", vm: vm) }
  let(:vm) { double("vm") }
  let(:comm) { double("comm") }
  let(:env) do
    double("env", machine: machine, active_machines: [machine])
  end

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive(:env).and_return(env)
  end

  describe ".configure_networks" do
    context "with network manager" do
      let(:network_1) do
        {
          interface: 1,
          type: "static",
          ip: "10.0.0.3",
          netmask: "255.255.255.0",
          mac_address: "00:00:00:00:00:00",
          gateway: "10.0.0.2",
        }
      end
      let(:network_2) do
        {
          interface: 2,
          type: "static",
          ip: "192.168.3.3",
          netmask: "255.255.0.0",
        }
      end
      let(:nm_list) do
        [
          "Wired connection 1:UUID_for_eth1:ethernet:eth1\n",
          "Wired connection 2:UUID_for_eth2:ethernet:eth2\n"
        ]
      end
      let(:interfaces) { ["eth0", "eth1", "eth2"] }
      let(:networks) do
        [
          network_1,
          network_2,
        ]
      end
      let(:tempfile) do
        double("tempfile",
          close: nil,
          delete: nil,
          path: temp_path,
        ).tap do |f|
          allow(f).to receive(:puts)
        end
      end
      let(:temp_path) { "/dev/null" }

      before do
        allow(guest).to receive(:capability).
          with(:network_interfaces).
          and_return(interfaces)
        allow(comm).to receive(:upload)
        allow(comm).to receive(:sudo)
        allow(comm).to receive(:execute)
        allow(Tempfile).to receive(:new).and_return(tempfile)

        expect(comm).to receive(:execute).
          with("nmcli -t c show") { |&block|
            nm_list.each { |line|
              block.call(:stdout, line)
            }
          }

        allow(comm).to receive(:test).
          with("command -v cloud-init").
          and_return(false)
      end

      it "should test for cloud-init" do
        expect(comm).to receive(:test).
          with("command -v cloud-init").
          and_return(false)
        described_class.configure_networks(machine, networks)
      end

      it "should remove any previous vagrant configuration" do
        expect(comm).to receive(:sudo).
          with(/rm .*vagrant-.*conf/, error_check: false)
        described_class.configure_networks(machine, networks)
      end

      it "should get MAC address from guest if not provided" do
        expect(comm).to receive(:execute).
          with(/cat .*eth2\/address/)
        described_class.configure_networks(machine, networks)
      end

      it "should not get MAC address from guest when provided" do
        expect(comm).not_to receive(:execute).
          with(/cat .*eth1\/address/)
        described_class.configure_networks(machine, networks)
      end

      it "should provide a default gateway when one is not provided" do
        expect(tempfile).to receive(:puts).
          with("gateway=192.168.0.1")
        described_class.configure_networks(machine, networks)
      end

      it "should use gateway value when provided" do
        expect(tempfile).to receive(:puts).
          with("gateway=10.0.0.2")
        described_class.configure_networks(machine, networks)
      end

      it "should disconnect device in network manager" do
        expect(comm).to receive(:sudo).
          with("nmcli d disconnect 'eth1'", error_check: false)
        expect(comm).to receive(:sudo).
          with("nmcli d disconnect 'eth2'", error_check: false)
        described_class.configure_networks(machine, networks)
      end

      it "should delete connection from network manager" do
        expect(comm).to receive(:sudo).
          with("nmcli c delete 'UUID_for_eth1'", error_check: false)
        expect(comm).to receive(:sudo).
          with("nmcli c delete 'UUID_for_eth2'", error_check: false)
        described_class.configure_networks(machine, networks)
      end

      it "should upload configuration files" do
        expect(comm).to receive(:upload).twice
        described_class.configure_networks(machine, networks)
      end

      it "should change file ownership to root" do
        expect(comm).to receive(:sudo).
          with(/chown root:root .*/)
        described_class.configure_networks(machine, networks)
      end

      it "should modify file permissions to remove read access" do
        expect(comm).to receive(:sudo).
          with(/chmod 0600 .*/)
        described_class.configure_networks(machine, networks)
      end

      it "should delete local temporary files" do
        expect(tempfile).to receive(:delete)
        described_class.configure_networks(machine, networks)
      end

      it "should load the configuration files into network manager" do
        expect(comm).to receive(:sudo).
          with(/nmcli c load .*conf/).twice
        described_class.configure_networks(machine, networks)
      end

      it "should connect the devices in network manager" do
        expect(comm).to receive(:sudo).
          with("nmcli d connect 'eth1'")
        expect(comm).to receive(:sudo).
          with("nmcli d connect 'eth2'")
        described_class.configure_networks(machine, networks)
      end
    end

    context "with cloud-init" do
      let(:interfaces) { ["eth0", "eth1", "lo"] }

      let(:network_1) do
        {
          interface: 0,
          type: "dhcp",
        }
      end
      let(:netconfig_1) do
        [:public_interface, {}]
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
      let(:netconfig_2) do
        [:public_network, {ip: "33.33.33.10", netmask: 16}]
      end
      let(:network_3) do
        {
          interface: 2,
          type: "static",
          ip: "192.168.120.22",
          netmask: "255.255.255.0",
          gateway: "192.168.120.1"
        }
      end
      let(:netconfig_3) do
        [:private_network, {ip: "192.168.120.22", netmask: 24}]
      end
      let(:networks) { [network_1, network_2, network_3] }
      let(:network_configs) { [netconfig_1, netconfig_2, netconfig_3] }
      let(:vm) { double("vm") }
      let(:default_env_ip) { described_class.const_get(:DEFAULT_ENVIRONMENT_IP) }

      before do
        allow(guest).to receive(:capability).with(:network_interfaces).
          and_return(interfaces)
        allow(vm).to receive(:networks).and_return(network_configs)
        allow(comm).to receive(:upload)
        allow(comm).to receive(:sudo)

        allow(comm).to receive(:test).
          with("command -v cloud-init").
          and_return(true)
      end

      it "should upload network configuration file" do
        expect(comm).to receive(:upload)
        described_class.configure_networks(machine, networks)
      end

      it "should configure public ipv4 address" do
        expect(comm).to receive(:upload) do |src, dst|
          content = File.read(src)
          expect(content).to include("COREOS_PUBLIC_IPV4=#{netconfig_2.last[:ip]}")
        end
        described_class.configure_networks(machine, networks)
      end

      it "should configure the private ipv4 address" do
        expect(comm).to receive(:upload) do |src, dst|
          content = File.read(src)
          expect(content).to include("COREOS_PRIVATE_IPV4=#{netconfig_3.last[:ip]}")
        end
        described_class.configure_networks(machine, networks)
      end

      it "should configure network interfaces" do
        expect(comm).to receive(:upload) do |src, dst|
          content = File.read(src)
          interfaces.each { |i| expect(content).to include("Name=#{i}") }
        end
        described_class.configure_networks(machine, networks)
      end

      it "should configure DHCP interface" do
        expect(comm).to receive(:upload) do |src, dst|
          content = File.read(src)
          expect(content).to include("DHCP=yes")
        end
        described_class.configure_networks(machine, networks)
      end

      it "should configure static IP addresses" do
        expect(comm).to receive(:upload) do |src, dst|
          content = File.read(src)
          network_configs.map(&:last).find_all { |c| c[:ip] }.each { |c|
            expect(content).to include("Address=#{c[:ip]}")
          }
        end
        described_class.configure_networks(machine, networks)
      end

      context "when no public network is defined" do
        let(:networks) { [network_1, network_3] }
        let(:network_configs) { [netconfig_1, netconfig_3] }


        it "should set public IP to the default environment IP" do
          expect(comm).to receive(:upload) do |src, dst|
            content = File.read(src)
            expect(content).to include("COREOS_PUBLIC_IPV4=#{default_env_ip}")
          end
          described_class.configure_networks(machine, networks)
        end

        it "should set the private IP to the private network" do
          expect(comm).to receive(:upload) do |src, dst|
            content = File.read(src)
            expect(content).to include("COREOS_PRIVATE_IPV4=#{netconfig_3.last[:ip]}")
          end
          described_class.configure_networks(machine, networks)
        end
      end

      context "when no private network is defined" do
        let(:networks) { [network_1, network_2] }
        let(:network_configs) { [netconfig_1, netconfig_2] }


        it "should set public IP to the public network" do
          expect(comm).to receive(:upload) do |src, dst|
            content = File.read(src)
            expect(content).to include("COREOS_PUBLIC_IPV4=#{netconfig_2.last[:ip]}")
          end
          described_class.configure_networks(machine, networks)
        end

        it "should set the private IP to the public IP" do
          expect(comm).to receive(:upload) do |src, dst|
            content = File.read(src)
            expect(content).to include("COREOS_PRIVATE_IPV4=#{netconfig_2.last[:ip]}")
          end
          described_class.configure_networks(machine, networks)
        end
      end

      context "when no public or private network is defined" do
        let(:networks) { [network_1] }
        let(:network_configs) { [netconfig_1] }


        it "should set public IP to the default environment IP" do
          expect(comm).to receive(:upload) do |src, dst|
            content = File.read(src)
            expect(content).to include("COREOS_PUBLIC_IPV4=#{default_env_ip}")
          end
          described_class.configure_networks(machine, networks)
        end

        it "should set the private IP to the default environment IP" do
          expect(comm).to receive(:upload) do |src, dst|
            content = File.read(src)
            expect(content).to include("COREOS_PRIVATE_IPV4=#{default_env_ip}")
          end
          described_class.configure_networks(machine, networks)
        end
      end
    end
  end
end
