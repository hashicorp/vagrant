require_relative "../../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/cap/linux/chef_installed")

describe VagrantPlugins::Chef::Cap::Linux::ChefInstalled do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:config)  { double("config") }

  subject { described_class }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
  end

  describe "#chef_installed" do
    let(:version) { "15.0.0" }
    let(:command) { "test -x /opt/chef_solo/bin/knife&& /opt/chef_solo/bin/knife --version | grep '15.0.0'" }

    it "returns true if installed" do
      expect(machine.communicate).to receive(:test).
        with(command, sudo: true).and_return(true)
      subject.chef_installed(machine, "chef_solo", version)
    end

    it "returns false if not installed" do
      expect(machine.communicate).to receive(:test).
        with(command, sudo: true).and_return(false)
      expect(subject.chef_installed(machine, "chef_solo", version)).to be_falsey
    end
  end
end
