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
  #  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:comm) { double("comm") }
  let(:env) do
    double("env", machine: machine, active_machines: [machine])
  end
  let(:interfaces) { ["eth0", "eth1", "lo"] }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive(:env).and_return(env)
  end

  describe ".configure_networks" do
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
