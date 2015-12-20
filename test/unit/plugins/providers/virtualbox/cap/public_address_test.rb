require_relative "../base"

require Vagrant.source_root.join("plugins/providers/virtualbox/cap/public_address")

describe VagrantPlugins::ProviderVirtualBox::Cap::PublicAddress do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      allow(m).to receive(:state).and_return(state)
    end
  end

  let(:state) do
    double(:state)
  end

  describe "#public_address" do
    it "returns nil when the machine is not running" do
      allow(state).to receive(:id).and_return(:not_created)
      expect(described_class.public_address(machine)).to be(nil)
    end

    it "returns nil when there is no ssh info" do
      allow(state).to receive(:id).and_return(:not_created)
      allow(machine).to receive(:ssh_info).and_return(nil)
      expect(described_class.public_address(machine)).to be(nil)
    end

    it "returns the host" do
      allow(state).to receive(:id).and_return(:running)
      allow(machine).to receive(:ssh_info).and_return(host: "test")
      expect(described_class.public_address(machine)).to eq("test")
    end
  end
end
