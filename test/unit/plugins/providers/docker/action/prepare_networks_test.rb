# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/prepare_networks"

describe VagrantPlugins::DockerProvider::Action::PrepareNetworks do
  include_context "unit"

  let(:sandbox) { isolated_environment }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    sandbox.vagrantfile("")
    sandbox.create_vagrant_env
  end

  let(:vm_config) { double("machine_vm_config") }

  let(:machine_config) do
    double("machine_config").tap do |top_config|
      allow(top_config).to receive(:vm).and_return(vm_config)
    end
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :docker).tap do |m|
      allow(m).to receive(:vagrantfile).and_return(vagrantfile)
      allow(m).to receive(:config).and_return(machine_config)
      allow(m.provider).to receive(:driver).and_return(driver)
      allow(m.config.vm).to receive(:networks).and_return(networks)
    end
  end

  let(:vagrantfile) { double("vagrantfile") }

  let(:env)    {{ machine: machine, ui: machine.ui, root_path: Pathname.new("."), vagrantfile: vagrantfile }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver", create: "abcd1234") }

  let(:networks) { [[:private_network,
          {:ip=>"172.20.128.2",
           :subnet=>"172.20.0.0/16",
           :driver=>"bridge",
           :internal=>"true",
           :alias=>"mynetwork",
           :protocol=>"tcp",
           :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58"}],
           [:public_network,
            {:ip=>"172.30.130.2",
             :subnet=>"172.30.0.0/16",
             :driver=>"bridge",
             :id=>"30e017d5-488f-5a2f-a3ke-k8dce8246b60"}],
         [:private_network,
          {:type=>"dhcp",
           :ipv6=>"true",
           :subnet=>"2a02:6b8:b010:9020:1::/80",
           :protocol=>"tcp",
           :id=>"b8f23054-38d5-45c3-99ea-d33fc5d1b9f2"}],
         [:forwarded_port,
          {:guest=>22, :host=>2200, :host_ip=>"127.0.0.1", :id=>"ssh", :auto_correct=>true, :protocol=>"tcp"}]]
  }

  let(:invalid_network) {
         [[:private_network,
          {:ipv6=>"true",
           :protocol=>"tcp",
           :id=>"b8f23054-38d5-45c3-99ea-d33fc5d1b9f2"}]]
        }

  subject { described_class.new(app, env) }

  let(:subprocess_result) do
    double("subprocess_result").tap do |result|
      allow(result).to receive(:exit_code).and_return(0)
      allow(result).to receive(:stdout).and_return("")
      allow(result).to receive(:stderr).and_return("")
    end
  end

  before do
    allow(Vagrant::Util::Subprocess).to receive(:execute).with("docker", "version", an_instance_of(Hash)).and_return(subprocess_result)
  end

  after do
    sandbox.close
  end

  describe "#call" do
    it "calls the next action in the chain" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_named_network?).and_return(false)
      allow(driver).to receive(:create_network).and_return(true)

      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)

      allow(action).to receive(:process_public_network).and_return(["name", {}])
      allow(action).to receive(:process_private_network).and_return(["name", {}])

      action.call(env)

      expect(called).to eq(true)
    end

    it "calls the proper driver methods to setup a network" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_named_network?).and_return(false)
      allow(driver).to receive(:network_containing_address).
        with("172.20.128.2").and_return(nil)
      allow(driver).to receive(:network_containing_address).
        with("192.168.1.1").and_return(nil)
      allow(driver).to receive(:network_defined?).with("172.20.128.0/24").
        and_return(false)
      allow(driver).to receive(:network_defined?).with("172.30.128.0/24").
        and_return(false)
      allow(driver).to receive(:network_defined?).with("2a02:6b8:b010:9020:1::/80").
        and_return(false)

      allow(subject).to receive(:request_public_gateway).and_return("1234")
      allow(subject).to receive(:request_public_iprange).and_return("1234")

      expect(subject).to receive(:process_private_network).with(networks[0][1], {}, env).
        and_return(["vagrant_network_172.20.128.0/24", {:ipv6=>false, :subnet=>"172.20.128.0/24"}])

      expect(subject).to receive(:process_public_network).with(networks[1][1], {}, env).
        and_return(["vagrant_network_public_wlp4s0", {"opt"=>"parent=wlp4s0", "subnet"=>"192.168.1.0/24", "driver"=>"macvlan", "gateway"=>"1234", "ipv6"=>false, "ip_range"=>"1234"}])

      expect(subject).to receive(:process_private_network).with(networks[2][1], {}, env).
        and_return(["vagrant_network_2a02:6b8:b010:9020:1::/80", {:ipv6=>true, :subnet=>"2a02:6b8:b010:9020:1::/80"}])

      allow(machine.ui).to receive(:ask).and_return("1")

      expect(driver).to receive(:create_network).
        with("vagrant_network_172.20.128.0/24", ["--subnet", "172.20.128.0/24"])
      expect(driver).to receive(:create_network).
        with("vagrant_network_public_wlp4s0", ["--opt", "parent=wlp4s0", "--subnet", "192.168.1.0/24", "--driver", "macvlan", "--gateway", "1234", "--ip-range", "1234"])
      expect(driver).to receive(:create_network).
        with("vagrant_network_2a02:6b8:b010:9020:1::/80", ["--ipv6", "--subnet", "2a02:6b8:b010:9020:1::/80"])

      subject.call(env)

      expect(env[:docker_connects]).to eq({0=>"vagrant_network_172.20.128.0/24", 1=>"vagrant_network_public_wlp4s0", 2=>"vagrant_network_2a02:6b8:b010:9020:1::/80"})
    end

    it "uses an existing network if a matching subnet is found" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:network_containing_address).
        with("172.20.128.2").and_return(nil)
      allow(driver).to receive(:network_containing_address).
        with("192.168.1.1").and_return(nil)
      allow(driver).to receive(:network_defined?).with("172.20.128.0/24").
        and_return("vagrant_network_172.20.128.0/24")
      allow(driver).to receive(:network_defined?).with("172.30.128.0/24").
        and_return("vagrant_network_public_wlp4s0")
      allow(driver).to receive(:network_defined?).with("2a02:6b8:b010:9020:1::/80").
        and_return("vagrant_network_2a02:6b8:b010:9020:1::/80")
      allow(machine.ui).to receive(:ask).and_return("1")

      expect(driver).to receive(:existing_named_network?).
        with("vagrant_network_172.20.128.0/24").and_return(true)
      expect(driver).to receive(:existing_named_network?).
        with("vagrant_network_public_wlp4s0").and_return(true)
      expect(driver).to receive(:existing_named_network?).
        with("vagrant_network_2a02:6b8:b010:9020:1::/80").and_return(true)

      expect(subject).to receive(:process_private_network).with(networks[0][1], {}, env).
        and_return(["vagrant_network_172.20.128.0/24", {:ipv6=>false, :subnet=>"172.20.128.0/24"}])

      expect(subject).to receive(:process_public_network).with(networks[1][1], {}, env).
        and_return(["vagrant_network_public_wlp4s0", {"opt"=>"parent=wlp4s0", "subnet"=>"192.168.1.0/24", "driver"=>"macvlan", "gateway"=>"1234", "ipv6"=>false, "ip_range"=>"1234"}])

      expect(subject).to receive(:process_private_network).with(networks[2][1], {}, env).
        and_return(["vagrant_network_2a02:6b8:b010:9020:1::/80", {:ipv6=>true, :subnet=>"2a02:6b8:b010:9020:1::/80"}])
      expect(driver).not_to receive(:create_network)

      expect(subject).to receive(:validate_network_configuration!).
        with("vagrant_network_172.20.128.0/24", networks[0][1],
            {:ipv6=>false, :subnet=>"172.20.128.0/24"}, driver)

      expect(subject).to receive(:validate_network_configuration!).
        with("vagrant_network_public_wlp4s0", networks[1][1],
             {"opt"=>"parent=wlp4s0", "subnet"=>"192.168.1.0/24", "driver"=>"macvlan", "gateway"=>"1234", "ipv6"=>false, "ip_range"=>"1234"}, driver)

      expect(subject).to receive(:validate_network_configuration!).
        with("vagrant_network_2a02:6b8:b010:9020:1::/80", networks[2][1],
            {:ipv6=>true, :subnet=>"2a02:6b8:b010:9020:1::/80"}, driver)

      subject.call(env)
    end

    it "raises an error if an inproper network configuration is given" do
      allow(machine.config.vm).to receive(:networks).and_return(invalid_network)
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_network?).and_return(false)

      expect{ subject.call(env) }.to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkIPAddressRequired)
    end
  end

  describe "#list_interfaces" do
    let(:interfaces){ ["192.168.1.2", "192.168.10.10"] }

    it "returns an array of interfaces to use" do
      allow(Socket).to receive(:getifaddrs).
            and_return(interfaces.map{|i| double(:socket, addr: Addrinfo.ip(i))})
      interfaces = subject.list_interfaces

      expect(subject.list_interfaces.size).to eq(2)
    end

    it "does not include an interface with the address is nil" do
      allow(Socket).to receive(:getifaddrs).
        and_return(interfaces.map{|i| double(:socket, addr: nil)})

      expect(subject.list_interfaces.size).to eq(0)
    end
  end

  describe "#generate_create_cli_arguments" do
    let(:network_options) {
            {:ip=>"172.20.128.2",
             :subnet=>"172.20.0.0/16",
             :driver=>"bridge",
             :internal=>"true",
             :alias=>"mynetwork",
             :protocol=>"tcp",
             :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58"} }

    let(:false_network_options) {
            {:ip=>"172.20.128.2",
             :subnet=>"172.20.0.0/16",
             :driver=>"bridge",
             :internal=>"false",
             :alias=>"mynetwork",
             :protocol=>"tcp",
             :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58"} }

    it "returns an array of cli arguments" do
      cli_args = subject.generate_create_cli_arguments(network_options)
      expect(cli_args).to eq( ["--ip", "172.20.128.2", "--subnet", "172.20.0.0/16", "--driver", "bridge", "--internal", "--alias", "mynetwork", "--protocol", "tcp", "--id", "80e017d5-388f-4a2f-a3de-f8dce8156a58"])
    end

    it "removes option if set to false" do
      cli_args = subject.generate_create_cli_arguments(false_network_options)
      expect(cli_args).to eq( ["--ip", "172.20.128.2", "--subnet", "172.20.0.0/16", "--driver", "bridge", "--alias", "mynetwork", "--protocol", "tcp", "--id", "80e017d5-388f-4a2f-a3de-f8dce8156a58"])
    end
  end

  describe "#validate_network_name!" do
    let(:netname) { "vagrant_network" }

    it "returns true if name exists" do
      allow(driver).to receive(:existing_named_network?).with(netname).
        and_return(true)

      expect(subject.validate_network_name!(netname, env)).to be_truthy
    end

    it "raises an error if name does not exist" do
      allow(driver).to receive(:existing_named_network?).with(netname).
        and_return(false)

      expect{subject.validate_network_name!(netname, env)}.to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkNameUndefined)
    end
  end

  describe "#validate_network_configuration!" do
    let(:netname) { "vagrant_network_172.20.128.0/24" }
    let(:options) { {:ip=>"172.20.128.2", :subnet=>"172.20.0.0/16", :driver=>"bridge", :internal=>"true", :alias=>"mynetwork", :protocol=>"tcp", :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58", :netmask=>24} }
    let(:network_options) { {:ipv6=>false, :subnet=>"172.20.128.0/24"} }

    it "returns true if all options are valid" do
      allow(driver).to receive(:network_containing_address).with(options[:ip]).
                                                                         and_return(netname)
      allow(driver).to receive(:network_containing_address).with(network_options[:subnet]).
                                                                         and_return(netname)

      expect(subject.validate_network_configuration!(netname, options, network_options, driver)).
        to be_truthy
    end

    it "raises an error of the address is invalid" do
      allow(driver).to receive(:network_containing_address).with(options[:ip]).
                                                                         and_return("fakename")
      expect{subject.validate_network_configuration!(netname, options, network_options, driver)}.
        to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkAddressInvalid)
    end

    it "raises an error of the subnet is invalid" do
      allow(driver).to receive(:network_containing_address).with(options[:ip]).
                                                                         and_return(netname)
      allow(driver).to receive(:network_containing_address).with(network_options[:subnet]).
                                                                         and_return("fakename")

      expect{subject.validate_network_configuration!(netname, options, network_options, driver)}.
        to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkSubnetInvalid)
    end
  end

  describe "#process_private_network" do
    let(:options) { {:ip=>"172.20.128.2", :subnet=>"172.20.0.0/16", :driver=>"bridge", :internal=>"true", :alias=>"mynetwork", :protocol=>"tcp", :id=>"80e017d5-388f-4a2f-a3de-f8dce8156a58", :netmask=>24} }
    let(:dhcp_options) { {type: "dhcp"} }
    let(:bad_options) { {driver: "bridge"} }

    it "generates a network name and config for a dhcp private network" do
      network_name, network_options = subject.process_private_network(dhcp_options, {}, env)

      expect(network_name).to eq("vagrant_network")
      expect(network_options).to eq({})
    end

    it "generates a network name and options for a static ip" do
      allow(driver).to receive(:network_defined?).and_return(nil)
      network_name, network_options = subject.process_private_network(options, {}, env)
      expect(network_name).to eq("vagrant_network_172.20.0.0/16")
      expect(network_options).to eq({:ipv6=>false, :subnet=>"172.20.0.0/16"})
    end

    it "raises an error if no ip address or type `dhcp` was given" do
      expect{subject.process_private_network(bad_options, {}, env)}.
        to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkIPAddressRequired)
    end
  end

  describe "#process_public_network" do
    let(:options) { {:ip=>"172.30.130.2", :subnet=>"172.30.0.0/16", :driver=>"bridge", :id=>"30e017d5-488f-5a2f-a3ke-k8dce8246b60"} }
    let(:addr) { double("addr", ip: true, ip_address: "192.168.1.139") }
    let(:netmask) { double("netmask", ip_unpack: ["255.255.255.0"]) }
    let(:ipaddr) { double("ipaddr", prefix: 22, succ: "10.1.10.2", ipv4?: true,
                          ipv6?: false, to_i: 4294967040, name: "ens20u1u2",
                          addr: addr, netmask: netmask) }

    it "raises an error if there are no network interfaces" do
      expect(subject).to receive(:list_interfaces).and_return([])

      expect{subject.process_public_network(options, {}, env)}.
        to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkNoInterfaces)
    end

    it "generates a network name and configuration" do
      allow(machine.ui).to receive(:ask).and_return("1")
      allow(subject).to receive(:request_public_gateway).and_return("1234")
      allow(subject).to receive(:request_public_iprange).and_return("1234")
      allow(IPAddr).to receive(:new).and_return(ipaddr)
      allow(driver).to receive(:existing_named_network?).and_return(false)
      allow(driver).to receive(:network_containing_address).
        with("10.1.10.2").and_return("vagrant_network_public")

      # mock the call to PrepareNetworks.list_interfaces so that we don't depend
      # on the current network interfaces
      allow(subject).to receive(:list_interfaces).
        and_return([ipaddr])

      network_name, _network_options = subject.process_public_network(options, {}, env)
      expect(network_name).to eq("vagrant_network_public")
    end
  end

  describe "#request_public_gateway" do
    let(:options) { {:ip=>"172.30.130.2", :subnet=>"172.30.0.0/16", :driver=>"bridge", :id=>"30e017d5-488f-5a2f-a3ke-k8dce8246b60"} }
    let(:ipaddr) { double("ipaddr", to_s: "172.30.130.2", prefix: 22, succ: "172.30.130.3",
                          ipv4?: true, ipv6?: false) }

    it "requests a gateway" do
      allow(IPAddr).to receive(:new).and_return(ipaddr)
      allow(ipaddr).to receive(:include?).and_return(false)
      allow(machine.ui).to receive(:ask).and_return("1")

      addr = subject.request_public_gateway(options, "bridge", env)

      expect(addr).to eq("172.30.130.2")
    end
  end

  describe "#request_public_iprange" do
    let(:options) { {:ip=>"172.30.130.2", :subnet=>"172.30.0.0/16", :driver=>"bridge", :id=>"30e017d5-488f-5a2f-a3ke-k8dce8246b60"} }
    let(:ipaddr) { double("ipaddr", to_s: "172.30.100.2", prefix: 22, succ: "172.30.100.3",
                          ipv4?: true, ipv6?: false) }
    let(:subnet) { double("ipaddr", to_s: "172.30.130.2", prefix: 22, succ: "172.30.130.3",
                          ipv6?: false) }

    let(:ipaddr_prefix) { double("ipaddr_prefix", to_s: "255.255.255.255/255.255.255.0",
                                 to_i: 4294967040 ) }

    let(:netmask) { double("netmask", ip_unpack: ["255.255.255.0", 0]) }
    let(:interface) { double("interface", name: "bridge", netmask: netmask) }

    it "requests a public ip range" do
      allow(IPAddr).to receive(:new).with(options[:subnet]).and_return(subnet)
      allow(IPAddr).to receive(:new).with("172.30.130.2").and_return(ipaddr)
      allow(IPAddr).to receive(:new).with("255.255.255.255/255.255.255.0").and_return(ipaddr_prefix)
      allow(subnet).to receive(:include?).and_return(true)
      allow(machine.ui).to receive(:ask).and_return(options[:ip])

      addr = subject.request_public_iprange(options, interface, env)
    end
  end
end
