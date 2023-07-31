# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../base"

require "vagrant/util/platform"

describe VagrantPlugins::ProviderVirtualBox::Action::Network do
  include_context "unit"
  include_context "virtualbox"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :virtualbox).tap do |m|
      allow(m.provider).to receive(:driver).and_return(driver)
    end
  end

  let(:env)    {{ machine: machine, ui: machine.ui }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver", version: vbox_version) }
  let(:vbox_version) { "6.1.0" }

  let(:nics)         { {} }

  subject { described_class.new(app, env) }

  before do
    allow(driver).to receive(:enable_adapters)
    allow(driver).to receive(:read_network_interfaces)   { nics }
  end

  describe "#hostonly_config" do
    before do
      allow(subject).to receive(:hostonly_find_matching_network)
      allow(driver).to receive(:read_bridged_interfaces).and_return([])
      subject.instance_eval do
        def env=(e)
          @env = e
        end
      end

      subject.env = env
    end

    let(:options) {
      {
        type: type,
        ip: address,
      }
    }
    let(:type) { :dhcp }
    let(:address) { nil }

    it "should validate the IP" do
      expect(subject).to receive(:validate_hostonly_ip!)
      subject.hostonly_config(options)
    end
  end

  describe "#validate_hostonly_ip!" do
    let(:address) { "192.168.1.2" }
    let(:net_conf) { [IPAddr.new(address + "/24")]}
    let(:vbox_version) { "6.1.28" }

    before do
      allow(subject).to receive(:load_net_conf).and_return(net_conf)
      expect(subject).to receive(:validate_hostonly_ip!).and_call_original
    end

    it "should load net configuration" do
      expect(subject).to receive(:load_net_conf).and_return(net_conf)
      subject.validate_hostonly_ip!(address, driver)
    end

    context "when address is within ranges" do
      it "should not error" do
        subject.validate_hostonly_ip!(address, driver)
      end
    end

    context "when address is not found within ranges" do
      let(:net_conf) { [IPAddr.new("127.0.0.1/20")] }

      it "should raise an error" do
        expect {
          subject.validate_hostonly_ip!(address, driver)
        }.to raise_error(Vagrant::Errors::VirtualBoxInvalidHostSubnet)
      end
    end

    context "when virtualbox version does not restrict range" do
      let(:vbox_version) { "6.1.20" }

      it "should not error" do
        subject.validate_hostonly_ip!(address, driver)
      end

      it "should not attempt to load network configuration" do
        expect(subject).not_to receive(:load_net_conf)
        subject.validate_hostonly_ip!(address, driver)
      end
    end

    context "when platform is windows" do
      before do
        allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)
      end

      it "should not error" do
        subject.validate_hostonly_ip!(address, driver)
      end

      it "should not attempt to load network configuration" do
        expect(subject).not_to receive(:load_net_conf)
        subject.validate_hostonly_ip!(address, driver)
      end
    end
  end

  describe "#load_net_conf" do
    let(:file_contents) { [""] }

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).
        with(described_class.const_get(:VBOX_NET_CONF)).
        and_return(true)
      allow(File).to receive(:readlines).
        with(described_class.const_get(:VBOX_NET_CONF)).
        and_return(file_contents)
    end

    it "should read the configuration file" do
      expect(File).to receive(:readlines).
        with(described_class.const_get(:VBOX_NET_CONF)).
        and_return(file_contents)

      subject.load_net_conf
    end

    context "when file has comments only" do
      let(:file_contents) {
        [
          "# A comment",
          "# Another comment",
        ]
      }

      it "should return an empty array" do
        expect(subject.load_net_conf).to eq([])
      end
    end

    context "when file has valid range entries" do
      let(:file_contents) {
        [
          "* 127.0.0.1/24",
          "* 192.168.1.1/24",
        ]
      }

      it "should return an array with content" do
        expect(subject.load_net_conf).not_to be_empty
      end

      it "should include IPAddr instances" do
        subject.load_net_conf.each do |entry|
          expect(entry).to be_a(IPAddr)
        end
      end
    end

    context "when file has valid range entries and comments" do
      let(:file_contents) {
        [
          "# Comment in file",
          "* 127.0.0.0/8",
          "random text",
          " * 192.168.2.0/28",
        ]
      }

      it "should contain two entries" do
        expect(subject.load_net_conf.size).to eq(2)
      end
    end

    context "when file has multiple entries on single line" do
      let(:file_contents) {
        [
          "* 0.0.0.0/0 ::/0"
        ]
      }

      it "should contain two entries" do
        expect(subject.load_net_conf.size).to eq(2)
      end

      it "should contain an ipv4 and ipv6 range" do
        result = subject.load_net_conf
        expect(result.first).to be_ipv4
        expect(result.last).to be_ipv6
      end
    end
  end

  it "calls the next action in the chain" do
    called = false
    app = lambda { |*args| called = true }

    action = described_class.new(app, env)
    action.call(env)

    expect(called).to eq(true)
  end

  it "creates a host-only interface with an IPv6 address <prefix>:1" do
    guest = double("guest")
    machine.config.vm.network 'private_network', type: :static, ip: 'dead:beef::100'
    #allow(driver).to receive(:read_bridged_interfaces) { [] }
    allow(driver).to receive(:read_host_only_interfaces) { [] }
    #allow(driver).to receive(:read_dhcp_servers) { [] }
    allow(machine).to receive(:guest) { guest }
    allow(driver).to receive(:create_host_only_network) {{ name: 'vboxnet0' }}
    allow(guest).to receive(:capability)
    interface_ip = 'dead:beef::1'

    subject.call(env)

    expect(driver).to have_received(:create_host_only_network).with(hash_including({
      adapter_ip: interface_ip,
      netmask: 64,
    }))

    expect(guest).to have_received(:capability).with(:configure_networks, [{
      type: :static6,
      adapter_ip: 'dead:beef::1',
      ip: 'dead:beef::100',
      netmask: 64,
      auto_config: true,
      interface: nil
    }])
  end

  it "raises the appropriate error when provided with an invalid IP address" do
    machine.config.vm.network 'private_network', ip: '192.168.33.06'

    expect{ subject.call(env) }.to raise_error(Vagrant::Errors::NetworkAddressInvalid)
  end

  context "with a dhcp private network" do
    let(:bridgedifs)  { [] }
    let(:hostonlyifs) { [] }
    let(:dhcpservers) { [] }
    let(:guest)       { double("guest") }
    let(:network_args) {{ type: :dhcp }}

    before do
      machine.config.vm.network 'private_network', **network_args
      allow(driver).to receive(:read_bridged_interfaces) { bridgedifs }
      allow(driver).to receive(:read_host_only_interfaces) { hostonlyifs }
      allow(driver).to receive(:read_dhcp_servers) { dhcpservers }
      allow(machine).to receive(:guest) { guest }
    end

    it "tries to setup dhpc server using the ip for the specified network" do
      allow(driver).to receive(:create_host_only_network) {{ name: 'vboxnet0' }}
      allow(driver).to receive(:create_dhcp_server)
      allow(guest).to receive(:capability)
      allow(subject).to receive(:hostonly_find_matching_network).and_return({name: "vboxnet1", ip: "192.168.55.1"})

      subject.call(env)

      expect(driver).to have_received(:create_dhcp_server).with('vboxnet1', {
        adapter_ip: "192.168.55.1",
        auto_config: true,
        ip: "192.168.55.1",
        mac: nil,
        name: nil,
        netmask: "255.255.255.0",
        nic_type: nil,
        type: :dhcp,
        dhcp_ip: "192.168.55.2",
        dhcp_lower: "192.168.55.3",
        dhcp_upper: "192.168.55.254",
        adapter: 2
      })

      expect(guest).to have_received(:capability).with(:configure_networks, [{
        type: :dhcp,
        adapter_ip: "192.168.55.1",
        ip: "192.168.55.1",
        netmask: "255.255.255.0",
        auto_config: true,
        interface: nil
      }])
    end

    it "creates a host only interface and a dhcp server using default ips, then tells the guest to configure the network after boot" do
      allow(driver).to receive(:create_host_only_network) {{ name: 'vboxnet0' }}
      allow(driver).to receive(:create_dhcp_server)
      allow(guest).to receive(:capability)
      allow(subject).to receive(:hostonly_find_matching_network).and_return(nil)

      subject.call(env)

      expect(driver).to have_received(:create_host_only_network).with(hash_including({
        adapter_ip: '192.168.56.1',
        netmask: '255.255.255.0',
      }))

      expect(driver).to have_received(:create_dhcp_server).with('vboxnet0', {
        adapter_ip: "192.168.56.1",
        auto_config: true,
        ip: "192.168.56.1",
        mac: nil,
        name: nil,
        netmask: "255.255.255.0",
        nic_type: nil,
        type: :dhcp,
        dhcp_ip: "192.168.56.2",
        dhcp_lower: "192.168.56.3",
        dhcp_upper: "192.168.56.254",
        adapter: 2
      })

      expect(guest).to have_received(:capability).with(:configure_networks, [{
        type: :dhcp,
        adapter_ip: "192.168.56.1",
        ip: "192.168.56.1",
        netmask: "255.255.255.0",
        auto_config: true,
        interface: nil
      }])
    end

    context "when the default vbox dhcpserver is present from a fresh vbox install (see issue #3803)" do
      let(:dhcpservers) {[
        {
          network_name: 'HostInterfaceNetworking-vboxnet0',
          network: 'vboxnet0',
          ip: '192.168.56.100',
          netmask: '255.255.255.0',
          lower: '192.168.56.101',
          upper: '192.168.56.254'
        }
      ]}

      it "removes the invalid dhcpserver so it won't collide with any host only interface" do
        allow(driver).to receive(:remove_dhcp_server)
        allow(driver).to receive(:create_host_only_network) {{ name: 'vboxnet0' }}
        allow(driver).to receive(:create_dhcp_server)
        allow(guest).to receive(:capability)

        subject.call(env)

        expect(driver).to have_received(:remove_dhcp_server).with('HostInterfaceNetworking-vboxnet0')
      end

      context "but the user has intentionally configured their network just that way" do
        let (:network_args) {{
          type: :dhcp,
          adapter_ip: '192.168.56.1',
          dhcp_ip: '192.168.56.100',
          dhcp_lower: '192.168.56.101',
          dhcp_upper: '192.168.56.254'
        }}

        it "does not attempt to remove the dhcpserver" do
          allow(driver).to receive(:remove_dhcp_server)
          allow(driver).to receive(:create_host_only_network) {{ name: 'vboxnet0' }}
          allow(driver).to receive(:create_dhcp_server)
          allow(guest).to receive(:capability)

          subject.call(env)

          expect(driver).not_to have_received(:remove_dhcp_server).with('HostInterfaceNetworking-vboxnet0')
        end
      end
    end
  end

  context 'with invalid settings' do
    [
      { ip: 'foo'},
      { ip: '1.2.3'},
      { ip: 'dead::beef::'},
      { ip: '192.168.56.3', netmask: 64},
      { ip: '192.168.56.3', netmask: 'ffff:ffff::'},
      { ip: 'dead:beef::', netmask: 'foo:bar::'},
      { ip: 'dead:beef::', netmask: '255.255.255.0'}
    ].each do |args|
      it 'raises an exception' do
        machine.config.vm.network 'private_network', **args
        expect { subject.call(env) }.
          to raise_error(Vagrant::Errors::NetworkAddressInvalid)
      end
    end
  end

  context "without type set" do
    before { allow(subject).to receive(:hostonly_adapter).and_return({}) }

    [
      { ip: "192.168.63.5" },
      { ip: "192.168.63.5", netmask: "255.255.255.0" },
      { ip: "dead:beef::100" },
      { ip: "dead:beef::100", netmask: 96 },
    ].each do |args|
      it "sets the type automatically" do
        machine.config.vm.network "private_network", **args
        expect(subject).to receive(:hostonly_config) do |config|
          expect(config).to have_key(:type)
          addr = IPAddr.new(args[:ip])
          if addr.ipv4?
            expect(config[:type]).to eq(:static)
          else
            expect(config[:type]).to eq(:static6)
          end
          config
        end
        subject.call(env)

      end
    end
  end

  describe "#hostonly_find_matching_network" do
    let(:ip){ "192.168.55.2" }
    let(:config){ {ip: ip, netmask: "255.255.255.0"} }
    let(:interfaces){ [] }

    before do
      allow(driver).to receive(:read_host_only_interfaces).and_return(interfaces)
      subject.instance_variable_set(:@env, env)
    end

    context "with no defined host interfaces" do
      it "should return nil" do
        expect(subject.hostonly_find_matching_network(config)).to be_nil
      end
    end

    context "with matching host interface" do
      let(:interfaces){ [{ip: "192.168.55.1", netmask: "255.255.255.0", name: "vnet"}] }

      it "should return matching interface" do
        expect(subject.hostonly_find_matching_network(config)).to eq(interfaces.first)
      end

      context "with matching name" do
        let(:config){ {ip: ip, netmask: "255.255.255.0", name: "vnet"} }

        it "should return matching interface" do
          expect(subject.hostonly_find_matching_network(config)).to eq(interfaces.first)
        end
      end

      context "with non-matching name" do
        let(:config){ {ip: ip, netmask: "255.255.255.0", name: "unknown"} }

        it "should return nil" do
          expect(subject.hostonly_find_matching_network(config)).to be_nil
        end
      end
    end
  end
end
