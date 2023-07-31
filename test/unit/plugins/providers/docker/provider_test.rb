# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/docker/provider")

describe VagrantPlugins::DockerProvider::Provider do
  let(:driver_obj){ double("driver") }
  let(:provider){ double("provider", driver: driver_obj) }
  let(:provider_config){ double("provider_config", force_host_vm: false) }
  let(:ssh) { double("ssh", guest_port: 22) }
  let(:config) { double("config", ssh: ssh) }
  let(:machine){ double("machine", provider: provider, provider_config: provider_config, config: config) }


  let(:platform)   { double("platform") }

  subject { described_class.new(machine) }

  before do
    stub_const("Vagrant::Util::Platform", platform)
    allow(machine).to receive(:id).and_return("foo")
  end

  describe ".usable?" do
    subject { described_class }

    it "returns true if usable" do
      allow(VagrantPlugins::DockerProvider::Driver).to receive(:new).and_return(driver_obj)
      allow(provider_config).to receive(:compose).and_return(false)
      allow(driver_obj).to receive(:execute).with("docker", "version").and_return(true)
      expect(subject).to be_usable
    end

    it "raises an exception if docker is not available" do
      allow(VagrantPlugins::DockerProvider::Driver).to receive(:new).and_return(driver_obj)
      allow(provider_config).to receive(:compose).and_return(false)
      allow(platform).to receive(:windows?).and_return(false)
      allow(platform).to receive(:darwin?).and_return(false)

      allow(driver_obj).to receive(:execute).with("docker", "version").
        and_raise(Vagrant::Errors::CommandUnavailable, file: "docker")

      expect { subject.usable?(true) }.
        to raise_error(Vagrant::Errors::CommandUnavailable)
    end
  end

  describe "#driver" do
    it "is initialized" do
      allow(provider_config).to receive(:compose).and_return(false)
      allow(platform).to receive(:windows?).and_return(false)
      allow(platform).to receive(:darwin?).and_return(false)
      expect(subject.driver).to be_kind_of(VagrantPlugins::DockerProvider::Driver)
    end
  end

  describe "#state" do
    before { allow(subject).to receive(:driver).and_return(driver_obj) }

    it "returns not_created if no ID" do
      allow(machine).to receive(:id).and_return(nil)
      expect(subject.state.id).to eq(:not_created)
    end

    it "calls an action to determine the ID" do
      allow(provider_config).to receive(:compose).and_return(false)
      allow(platform).to receive(:windows?).and_return(false)
      allow(platform).to receive(:darwin?).and_return(false)
      expect(machine).to receive(:id).and_return("foo")
      expect(driver_obj).to receive(:created?).with("foo").and_return(false)

      expect(subject.state.id).to eq(:not_created)
    end
  end

  describe "#host_vm" do
    let(:host_env) { double("host_env", root_path: "/vagrant.d", default_provider: :virtualbox) }

    it "returns the host machine object" do
      allow(machine.provider_config).to receive(:vagrant_vagrantfile).and_return("/path/to/Vagrantfile")
      allow(machine.provider_config).to receive(:vagrant_machine).and_return(:default)
      allow(machine).to receive(:env).and_return(double("env"))
      allow(machine.env).to receive(:root_path).and_return("/.vagrant.d")
      allow(machine.env).to receive(:home_path).and_return("/path/to")
      allow(machine.env).to receive(:ui_class).and_return(true)

      expect(Vagrant::Environment).to receive(:new).and_return(host_env)

      allow(host_env).to receive(:machine).and_return(true)
      subject.host_vm
    end
  end

  describe "#ssh_info" do
    let(:result) { "127.0.0.1" }
    let(:exit_code) { 0 }
    let(:ssh_info) {{:host=>result,:port=>22}}

    let(:network_settings) { {"NetworkSettings" => {"Bridge"=>"", "SandboxID"=>"randomid", "HairpinMode"=>false, "LinkLocalIPv6Address"=>"", "LinkLocalIPv6PrefixLen"=>0, "Ports"=>{"443/tcp"=>nil, "80/tcp"=>nil}, "SandboxKey"=>"/var/run/docker/netns/158b7024a9e4", "SecondaryIPAddresses"=>nil, "SecondaryIPv6Addresses"=>nil, "EndpointID"=>"randomEndpointID", "Gateway"=>"172.17.0.1", "GlobalIPv6Address"=>"", "GlobalIPv6PrefixLen"=>0, "IPAddress"=>"127.0.0.1", "IPPrefixLen"=>16, "IPv6Gateway"=>"", "MacAddress"=>"02:42:ac:11:00:02", "Networks"=>{"bridge"=>{"IPAMConfig"=>nil, "Links"=>nil, "Aliases"=>nil, "NetworkID"=>"networkIDVar", "EndpointID"=>"endpointIDVar", "Gateway"=>"127.0.0.1", "IPAddress"=>"127.0.0.1", "IPPrefixLen"=>16, "IPv6Gateway"=>"", "GlobalIPv6Address"=>"", "GlobalIPv6PrefixLen"=>0, "MacAddress"=>"02:42:ac:11:00:02", "DriverOpts"=>nil}}}} }

    let(:empty_network_settings) { {"NetworkSettings" => {"Bridge"=>"", "SandboxID"=>"randomid", "HairpinMode"=>false, "LinkLocalIPv6Address"=>"", "LinkLocalIPv6PrefixLen"=>0, "Ports"=>"", "SandboxKey"=>"/var/run/docker/netns/158b7024a9e4", "SecondaryIPAddresses"=>nil, "SecondaryIPv6Addresses"=>nil, "EndpointID"=>"randomEndpointID", "Gateway"=>"172.17.0.1", "GlobalIPv6Address"=>"", "GlobalIPv6PrefixLen"=>0, "IPAddress"=>"", "IPPrefixLen"=>16, "IPv6Gateway"=>"", "MacAddress"=>"02:42:ac:11:00:02", "Networks"=>{"bridge"=>{"IPAMConfig"=>nil, "Links"=>nil, "Aliases"=>nil, "NetworkID"=>"networkIDVar", "EndpointID"=>"endpointIDVar", "Gateway"=>"127.0.0.1", "IPAddress"=>"127.0.0.1", "IPPrefixLen"=>16, "IPv6Gateway"=>"", "GlobalIPv6Address"=>"", "GlobalIPv6PrefixLen"=>0, "MacAddress"=>"02:42:ac:11:00:02", "DriverOpts"=>nil}}}} }

    before do
      allow(VagrantPlugins::DockerProvider::Driver).to receive(:new).and_return(driver_obj)
      allow(machine).to receive(:action).with(:read_state).and_return(machine_state_id: :running)
    end

    it "returns nil if a port info is nil from the driver" do
      allow(provider_config).to receive(:compose).and_return(false)
      allow(platform).to receive(:windows?).and_return(false)
      allow(platform).to receive(:darwin?).and_return(false)
      allow(driver_obj).to receive(:created?).and_return(true)
      allow(driver_obj).to receive(:state).and_return(:running)

      allow(driver_obj).to receive(:inspect_container).and_return(empty_network_settings)

      expect(subject.ssh_info).to eq(nil)
    end

    it "should receive a valid address" do
      allow(provider_config).to receive(:compose).and_return(false)
      allow(platform).to receive(:windows?).and_return(false)
      allow(platform).to receive(:darwin?).and_return(false)
      allow(driver_obj).to receive(:created?).and_return(true)
      allow(driver_obj).to receive(:state).and_return(:running)
      allow(driver_obj).to receive(:execute).with(:get_network_config).and_return(result)
      allow(driver_obj).to receive(:inspect_container).and_return(network_settings)

      expect(subject.ssh_info).to eq(ssh_info)
    end
  end
end
