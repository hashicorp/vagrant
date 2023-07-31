# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/connect_networks"


describe VagrantPlugins::DockerProvider::Action::ConnectNetworks do
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
      allow(m).to receive(:id).and_return("12345")
      allow(m.provider).to receive(:driver).and_return(driver)
      allow(m.provider).to receive(:host_vm?).and_return(false)
      allow(m.config.vm).to receive(:networks).and_return(networks)
    end
  end

  let(:docker_connects) { {0=>"vagrant_network_172.20.0.0/16", 1=>"vagrant_network_public_wlp4s0", 2=>"vagrant_network_2a02:6b8:b010:9020:1::/80"} }

  let(:vagrantfile) { double("vagrantfile") }

  let(:env)    {{ machine: machine, ui: machine.ui, root_path: Pathname.new("."),
                  docker_connects: docker_connects, vagrantfile: vagrantfile }}
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
      allow(driver).to receive(:connect_network).and_return(true)

      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)

      action.call(env)

      expect(called).to eq(true)
    end

    it "connects all of the available networks to a container" do
      expect(driver).to receive(:connect_network).with("vagrant_network_172.20.0.0/16", "12345", ["--ip", "172.20.128.2", "--alias", "mynetwork"])
      expect(driver).to receive(:connect_network).with("vagrant_network_public_wlp4s0", "12345", ["--ip", "172.30.130.2"])
      expect(driver).to receive(:connect_network).with("vagrant_network_2a02:6b8:b010:9020:1::/80", "12345", [])

      subject.call(env)
    end

    context "with missing env values" do
      it "raises an error if the network name is missing" do
        env[:docker_connects] = {}

        expect{subject.call(env)}.to raise_error(VagrantPlugins::DockerProvider::Errors::NetworkNameMissing)
      end
    end
  end

  describe "#generate_connect_cli_arguments" do
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

    it "removes false values" do
      cli_args = subject.generate_connect_cli_arguments(false_network_options)
      expect(cli_args).to eq(["--ip", "172.20.128.2", "--subnet", "172.20.0.0/16", "--driver", "bridge", "--alias", "mynetwork", "--protocol", "tcp", "--id", "80e017d5-388f-4a2f-a3de-f8dce8156a58"])
    end

    it "removes true and leaves flag value in arguments" do
      cli_args = subject.generate_connect_cli_arguments(network_options)
      expect(cli_args).to eq(["--ip", "172.20.128.2", "--subnet", "172.20.0.0/16", "--driver", "bridge", "--internal", "--alias", "mynetwork", "--protocol", "tcp", "--id", "80e017d5-388f-4a2f-a3de-f8dce8156a58"])
    end

    it "takes options and generates cli flags" do
      cli_args = subject.generate_connect_cli_arguments(network_options)
      expect(cli_args).to eq(["--ip", "172.20.128.2", "--subnet", "172.20.0.0/16", "--driver", "bridge", "--internal", "--alias", "mynetwork", "--protocol", "tcp", "--id", "80e017d5-388f-4a2f-a3de-f8dce8156a58"])
    end
  end
end
