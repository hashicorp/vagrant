# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/destroy_network"

describe VagrantPlugins::DockerProvider::Action::DestroyNetwork do
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
    let(:network_names) { ["vagrant_network_172.20.0.0/16", "vagrant_network_2a02:6b8:b010:9020:1::/80"] }

    it "calls the next action in the chain" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_network?).and_return(true)
      allow(driver).to receive(:network_used?).and_return(true)
      allow(driver).to receive(:list_network_names).and_return([])

      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)
      action.call(env)

      expect(called).to eq(true)
    end

    it "calls the proper driver method to destroy the network" do
      allow(driver).to receive(:list_network_names).and_return(network_names)
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:existing_named_network?).with("vagrant_network_172.20.0.0/16").
                                                         and_return(true)
      allow(driver).to receive(:network_used?).with("vagrant_network_172.20.0.0/16").
                                                         and_return(false)
      allow(driver).to receive(:existing_named_network?).with("vagrant_network_2a02:6b8:b010:9020:1::/80").
                                                         and_return(true)
      allow(driver).to receive(:network_used?).with("vagrant_network_2a02:6b8:b010:9020:1::/80").
                                                         and_return(false)

      expect(driver).to receive(:rm_network).with("vagrant_network_172.20.0.0/16").twice
      expect(driver).to receive(:rm_network).with("vagrant_network_2a02:6b8:b010:9020:1::/80").twice

      subject.call(env)
    end

    it "doesn't destroy the network if another container is still using it" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:list_network_names).and_return(network_names)
      allow(driver).to receive(:existing_named_network?).with("vagrant_network_172.20.0.0/16").
                                                         and_return(true)
      allow(driver).to receive(:network_used?).with("vagrant_network_172.20.0.0/16").
                                                         and_return(true)
      allow(driver).to receive(:existing_named_network?).with("vagrant_network_2a02:6b8:b010:9020:1::/80").
                                                         and_return(true)
      allow(driver).to receive(:network_used?).with("vagrant_network_2a02:6b8:b010:9020:1::/80").
                                                         and_return(true)

      expect(driver).not_to receive(:rm_network).with("vagrant_network_172.20.0.0/16")
      expect(driver).not_to receive(:rm_network).with("vagrant_network_2a02:6b8:b010:9020:1::/80")

      subject.call(env)
    end
  end
end
