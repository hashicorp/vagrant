require_relative "../../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/cap/windows/chef_installed")

describe VagrantPlugins::Chef::Cap::Windows::ChefInstalled do
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
      let(:command) { "if ((&chef --version) -Match \"17.0.0\"){ exit 0 } else { exit 1 }" }

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
      let(:command) { "if ((&cinc --version) -Match \"17.0.0\"){ exit 0 } else { exit 1 }" }

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
      let(:command) { "if ((&cinc-client --version) -Match \"17.0.0\"){ exit 0 } else { exit 1 }" }

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
      let(:command) { "if ((&chef-client --version) -Match \"17.0.0\"){ exit 0 } else { exit 1 }" }

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
end
