# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/login"


describe VagrantPlugins::DockerProvider::Action::Login do
  include_context "unit"

  let(:sandbox) { isolated_environment }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    sandbox.vagrantfile("")
    sandbox.create_vagrant_env
  end

  let(:provider_config) { double("provider_config", username: "docker", password: "") }

  let(:vm_config) { double("machine_vm_config") }

  let(:machine_config) do
    double("machine_config").tap do |top_config|
      allow(top_config).to receive(:vm).and_return(vm_config)
    end
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :docker).tap do |m|
      allow(m).to receive(:id).and_return("12345")
      allow(m).to receive(:config).and_return(machine_config)
      allow(m).to receive(:provider_config).and_return(provider_config)
      allow(m).to receive(:vagrantfile).and_return(vagrantfile)
      allow(m.provider).to receive(:driver).and_return(driver)
      allow(m.provider).to receive(:host_vm?).and_return(false)
    end
  end

  let(:vagrantfile) { double("vagrantfile") }

  let(:env)    {{ machine: machine, ui: machine.ui, root_path: Pathname.new("."), vagrantfile: vagrantfile }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver", create: "abcd1234") }


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

      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)

      action.call(env)

      expect(called).to eq(true)
    end

    it "uses a host vm lock if host_vm is true and password is set" do
      allow(driver).to receive(:host_vm?).and_return(true)
      allow(driver).to receive(:login).and_return(true)
      allow(driver).to receive(:logout).and_return(true)

      allow(machine.provider).to receive(:host_vm?).and_return(true)
      allow(machine.provider).to receive(:host_vm_lock) { |&block| block.call }

      allow(provider_config).to receive(:password).and_return("docker")
      allow(provider_config).to receive(:email).and_return("docker")
      allow(provider_config).to receive(:auth_server).and_return("docker")

      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)

      action.call(env)

      expect(called).to eq(true)
    end

    it "doesn't use the host vm if not set" do
      allow(driver).to receive(:host_vm?).and_return(false)
      allow(driver).to receive(:login).and_return(true)
      allow(driver).to receive(:logout).and_return(true)

      allow(machine.provider).to receive(:host_vm?).and_return(false)

      allow(provider_config).to receive(:password).and_return("docker")
      allow(provider_config).to receive(:email).and_return("docker")
      allow(provider_config).to receive(:auth_server).and_return("docker")

      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)

      action.call(env)

      expect(called).to eq(true)
    end
  end
end
