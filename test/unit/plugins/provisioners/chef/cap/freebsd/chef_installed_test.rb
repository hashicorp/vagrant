require_relative "../../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/cap/freebsd/chef_installed")

describe VagrantPlugins::Chef::Cap::FreeBSD::ChefInstalled do
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
    describe "when chef-workstation" do
      let(:version) { "17.0.0" }
      let(:command) { "test -x /opt/chef-workstation/bin/chef&& /opt/chef-workstation/bin/chef --version | grep '17.0.0'" }

      it "returns true if installed" do
        expect(machine.communicate).to receive(:test).
          with(command, sudo: true).and_return(true)
        subject.chef_installed(machine, "chef-workstation", version)
      end

      it "returns false if not installed" do
        expect(machine.communicate).to receive(:test).
          with(command, sudo: true).and_return(false)
        expect(subject.chef_installed(machine, "chef-workstation", version)).to be_falsey
      end
    end

    describe "when cinc-workstation" do
      let(:version) { "17.0.0" }
      let(:command) { "test -x /opt/cinc-workstation/bin/cinc&& /opt/cinc-workstation/bin/cinc --version | grep '17.0.0'" }

      it "returns true if installed" do
        expect(machine.communicate).to receive(:test).
          with(command, sudo: true).and_return(true)
        subject.chef_installed(machine, "cinc-workstation", version)
      end

      it "returns false if not installed" do
        expect(machine.communicate).to receive(:test).
          with(command, sudo: true).and_return(false)
        expect(subject.chef_installed(machine, "cinc-workstation", version)).to be_falsey
      end
    end

    describe "when cinc" do
      let(:version) { "17.0.0" }
      let(:command) { "test -x /opt/cinc/bin/cinc-client&& /opt/cinc/bin/cinc-client --version | grep '17.0.0'" }

      it "returns true if installed" do
        expect(machine.communicate).to receive(:test).
          with(command, sudo: true).and_return(true)
        subject.chef_installed(machine, "cinc", version)
      end

      it "returns false if not installed" do
        expect(machine.communicate).to receive(:test).
          with(command, sudo: true).and_return(false)
        expect(subject.chef_installed(machine, "cinc", version)).to be_falsey
      end
    end

    describe "when default (chef)" do
      let(:version) { "17.0.0" }
      let(:command) { "test -x /opt/chef/bin/chef-client&& /opt/chef/bin/chef-client --version | grep '17.0.0'" }

      it "returns true if installed" do
        expect(machine.communicate).to receive(:test).
          with(command, sudo: true).and_return(true)
        subject.chef_installed(machine, "chef", version)
      end

      it "returns false if not installed" do
        expect(machine.communicate).to receive(:test).
          with(command, sudo: true).and_return(false)
        expect(subject.chef_installed(machine, "chef", version)).to be_falsey
      end
    end
  end
end
