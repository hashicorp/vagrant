# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/puppet/provisioner/puppet")

describe VagrantPlugins::Puppet::Provisioner::Puppet do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:config)       { double("config") }
  let(:facts)        { [] }
  let(:communicator) { double("comm") }
  let(:guest)        { double("guest") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:module_paths) { ["etc/puppet/modules"] } # make this something real

  subject { described_class.new(machine, config) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  describe "#run_puppet_apply" do
    let(:options) { "--environment production" }
    let(:binary_path) { "/opt/puppetlabs/bin" }
    let(:manifest_file) { "default.pp" }

    it "runs puppet on a manifest" do
      allow(config).to receive(:options).and_return(options)
      allow(config).to receive(:environment_path).and_return(false)
      allow(config).to receive(:facter).and_return(facts)
      allow(config).to receive(:binary_path).and_return(binary_path)
      allow(config).to receive(:environment_variables).and_return({hello: "there", test: "test"})
      allow(config).to receive(:working_directory).and_return(false)
      allow(config).to receive(:manifest_file).and_return(manifest_file)
      allow(config).to receive(:structured_facts).and_return(double("structured_facts"))

      allow_message_expectations_on_nil
      allow(@module_paths).to receive(:map) { module_paths }
      allow(@module_paths).to receive(:empty?).and_return(true)

      expect(machine).to receive(:communicate).and_return(comm)
      expect(machine.communicate).to receive(:sudo).with("hello=\"there\" test=\"test\" /opt/puppetlabs/bin/puppet apply --environment production --color=false --detailed-exitcodes ", anything)

      subject.run_puppet_apply()
    end

    it "properly sets env variables on windows" do
      allow(config).to receive(:options).and_return(options)
      allow(config).to receive(:environment_path).and_return(false)
      allow(config).to receive(:facter).and_return(facts)
      allow(config).to receive(:binary_path).and_return(binary_path)
      allow(config).to receive(:environment_variables).and_return({hello: "there", test: "test"})
      allow(config).to receive(:working_directory).and_return(false)
      allow(config).to receive(:manifest_file).and_return(manifest_file)
      allow(config).to receive(:structured_facts).and_return(double("structured_facts"))
      allow(subject).to receive(:windows?).and_return(true)

      allow_message_expectations_on_nil
      allow(@module_paths).to receive(:map) { module_paths }
      allow(@module_paths).to receive(:empty?).and_return(true)

      expect(machine).to receive(:communicate).and_return(comm)
      expect(machine.communicate).to receive(:sudo).with("$env:hello=\"there\"; $env:test=\"test\"; /opt/puppetlabs/bin/puppet apply --environment production --color=false --detailed-exitcodes ", anything)

      subject.run_puppet_apply()
    end
  end

  describe "#provision" do
    let(:options) { double("options") }
    let(:binary_path) { "/opt/puppetlabs/bin" }
    let(:manifest_file) { "default.pp" }
    let(:module_paths) { ["etc/puppet/modules"] } # make this something real
    let(:environment_paths) { ["/etc/puppet/environment"] }

    it "builds structured facts if set" do
      allow(machine).to receive(:guest).and_return(double("guest"))
      allow(machine.guest).to receive(:capability?).and_return(false)
      allow(config).to receive(:environment_path).and_return(environment_paths)
      allow(config).to receive(:environment).and_return("production")
      allow(config).to receive(:manifests_path).and_return(manifest_file)
      allow(config).to receive(:temp_dir).and_return("/tmp")
      allow(config).to receive(:hiera_config_path).and_return(false)
      allow(subject).to receive(:parse_environment_metadata).and_return(true)
      allow(subject).to receive(:verify_binary).and_return(true)
      allow(subject).to receive(:run_puppet_apply).and_return(true)

      allow_message_expectations_on_nil
      allow(@module_paths).to receive(:each) { module_paths }

      allow(config).to receive(:facter).and_return({"coolfacts"=>"here they are"})
      allow(config).to receive(:structured_facts).and_return(true)

      expect(machine.communicate).to receive(:upload).with(anything, "/tmp/vagrant_facts.yaml")
      expect(machine.communicate).to receive(:sudo).with("mkdir -p /tmp; chmod 0777 /tmp", {})
      expect(machine.communicate).to receive(:sudo).with("cp /tmp/vagrant_facts.yaml /etc/puppetlabs/facter/facts.d/vagrant_facts.yaml")
      subject.provision()
    end

    it "does not build structured facts if not set" do
      allow(machine).to receive(:guest).and_return(double("guest"))
      allow(machine.guest).to receive(:capability?).and_return(false)
      allow(config).to receive(:environment_path).and_return(environment_paths)
      allow(config).to receive(:environment).and_return("production")
      allow(config).to receive(:manifests_path).and_return(manifest_file)
      allow(config).to receive(:temp_dir).and_return("/tmp")
      allow(config).to receive(:hiera_config_path).and_return(false)
      allow(subject).to receive(:parse_environment_metadata).and_return(true)
      allow(subject).to receive(:verify_binary).and_return(true)
      allow(subject).to receive(:run_puppet_apply).and_return(true)

      allow_message_expectations_on_nil
      allow(@module_paths).to receive(:each) { module_paths }

      allow(config).to receive(:facter).and_return({"coolfacts"=>"here they are"})
      allow(config).to receive(:structured_facts).and_return(nil)

      expect(machine.communicate).not_to receive(:upload).with(anything, "/tmp/vagrant_facts.yaml")
      expect(machine.communicate).not_to receive(:sudo).with("cp /tmp/vagrant_facts.yaml /etc/puppetlabs/facter/facts.d/vagrant_facts.yaml")
      subject.provision()
    end
  end
end
