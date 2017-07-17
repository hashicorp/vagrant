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
    let(:options) { double("options") }
    let(:binary_path) { "/opt/puppetlabs/bin" }
    let(:manifest_file) { "default.pp" }

    it "runs puppet on a manifest" do
      allow(config).to receive(:options).and_return(options)
      allow(config).to receive(:environment_path).and_return(false)
      allow(config).to receive(:facter).and_return(facts)
      allow(config).to receive(:binary_path).and_return(binary_path)
      allow(config).to receive(:environment_variables).and_return(nil)
      allow(config).to receive(:working_directory).and_return(false)
      allow(config).to receive(:manifest_file).and_return(manifest_file)

      allow_message_expectations_on_nil
      allow(@module_paths).to receive(:map) { module_paths }
      allow(@module_paths).to receive(:empty?).and_return(true)

      expect(machine).to receive(:communicate).and_return(comm)
      subject.run_puppet_apply()
    end
  end
end
