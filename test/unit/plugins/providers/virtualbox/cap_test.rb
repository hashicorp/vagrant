require_relative "base"

require Vagrant.source_root.join("plugins/providers/virtualbox/cap")

describe VagrantPlugins::ProviderVirtualBox::Cap do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :dummy).tap do |m|
      m.provider.stub(driver: driver)
    end
  end

  let(:driver) { double("driver") }

  describe "#forwarded_ports" do
    it "returns all the forwarded ports" do
      expect(driver).to receive(:read_forwarded_ports).and_return([
        [nil, nil, 123, 456],
        [nil, nil, 245, 245],
      ])

      expect(described_class.forwarded_ports(machine)).to eq({
        123 => 456,
        245 => 245,
      })
    end
  end
end
