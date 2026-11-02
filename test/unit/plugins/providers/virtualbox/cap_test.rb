# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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
      allow(m.provider).to receive(:driver).and_return(driver)
      allow(m).to receive(:state).and_return(state)
    end
  end

  let(:driver) { double("driver") }
  let(:state)  { double("state", id: :running) }

  describe "#forwarded_ports" do
    it "returns all the forwarded ports" do
      allow(driver).to receive(:read_forwarded_ports).and_return([
        [nil, nil, 123, 456],
        [nil, nil, 245, 245],
      ])

      expect(described_class.forwarded_ports(machine)).to eq({
        123 => 456,
        245 => 245,
      })
    end

    it "returns nil when the machine is not running" do
      allow(machine).to receive(:state).and_return(double(:state, id: :stopped))
      expect(described_class.forwarded_ports(machine)).to be(nil)
    end
  end

  describe "#snapshot_list" do
    it "returns all the snapshots" do
      allow(machine).to receive(:id).and_return("1234")
      allow(driver).to receive(:list_snapshots).with(machine.id).
        and_return(["backup", "old"])

      expect(described_class.snapshot_list(machine)).to eq(["backup", "old"])
    end

    it "returns empty array when the machine is does not exist" do
      allow(machine).to receive(:id).and_return(nil)
      expect(described_class.snapshot_list(machine)).to eq([])
    end
  end
end
