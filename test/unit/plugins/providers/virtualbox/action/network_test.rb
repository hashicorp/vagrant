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
      m.provider.stub(driver: driver)
    end
  end

  let(:env)    {{ machine: machine, ui: machine.ui }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver") }

  let(:nics)         { {} }

  subject { described_class.new(app, env) }

  before do
    allow(driver).to receive(:enable_adapters)
    allow(driver).to receive(:read_network_interfaces)   { nics }
  end

  it "calls the next action in the chain" do
    called = false
    app = lambda { |*args| called = true }

    action = described_class.new(app, env)
    action.call(env)

    expect(called).to eq(true)
  end

  context "with a dhcp private network" do
    let(:bridgedifs)  { [] }
    let(:hostonlyifs) { [] }
    let(:dhcpservers) { [] }
    let(:guest)       { double("guest") }
    let(:network_args) {{ type: :dhcp }}

    before do
      machine.config.vm.network 'private_network', network_args
      allow(driver).to receive(:read_bridged_interfaces) { bridgedifs }
      allow(driver).to receive(:read_host_only_interfaces) { hostonlyifs }
      allow(driver).to receive(:read_dhcp_servers) { dhcpservers }
      allow(machine).to receive(:guest) { guest }
    end

    it "creates a host only interface and a dhcp server using default ips, then tells the guest to configure the network after boot" do
      allow(driver).to receive(:create_host_only_network) {{ name: 'vboxnet0' }}
      allow(driver).to receive(:create_dhcp_server)
      allow(guest).to receive(:capability)

      subject.call(env)

      expect(driver).to have_received(:create_host_only_network).with({
        adapter_ip: '172.28.128.1',
        netmask: '255.255.255.0',
      })

      expect(driver).to have_received(:create_dhcp_server).with('vboxnet0', {
        adapter_ip: "172.28.128.1",
        auto_config: true,
        ip: "172.28.128.1",
        mac: nil,
        name: nil,
        netmask: "255.255.255.0",
        nic_type: nil,
        type: :dhcp,
        dhcp_ip: "172.28.128.2",
        dhcp_lower: "172.28.128.3",
        dhcp_upper: "172.28.128.254",
        adapter: 2
      })

      expect(guest).to have_received(:capability).with(:configure_networks, [{
        type: :dhcp,
        adapter_ip: "172.28.128.1",
        ip: "172.28.128.1",
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
end
