# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/snapshot/command/pop")

describe VagrantPlugins::CommandSnapshot::Command::Pop do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest)   { double("guest") }
  let(:host)    { double("host") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  let(:argv)     { [] }

  subject { described_class.new(argv, iso_env) }

  before do
    allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
  end

  describe "execute" do
    before do
      machine.id = "mach"
      allow(machine.provider).to receive(:capability).
        with(:snapshot_list).and_return(["push_2_0"])
    end

    it "calls snapshot_restore with the last pushed snapshot" do
      machine.id = "foo"

      allow(machine.provider).to receive(:capability).
        with(:snapshot_list).and_return(["push_2_0", "push_1_0"])

      expect(machine).to receive(:action) do |name, opts|
        expect(name).to eq(:snapshot_restore)
        expect(opts[:snapshot_name]).to eq("push_2_0")
      end

      expect(subject.execute).to eq(0)
    end

    it "isn't an error if no matching snapshot" do
      machine.id = "foo"

      allow(machine.provider).to receive(:capability).
        with(:snapshot_list).and_return(["foo"])

      expect(machine).to_not receive(:action)
      expect(subject.execute).to eq(0)
    end

    it "should disable ignoring sentinel file for provisioning" do
      expect(machine).to receive(:action) do |name, opts|
        expect(name).to eq(:snapshot_restore)
        expect(opts[:provision_ignore_sentinel]).to eq(false)
      end
      subject.execute
    end

    it "should start the snapshot" do
      expect(machine).to receive(:action) do |name, opts|
        expect(name).to eq(:snapshot_restore)
        expect(opts[:snapshot_start]).to eq(true)
      end
      subject.execute
    end

    context "when --no-start flag is provided" do
      let(:argv) { ["--no-start"] }

      it "should not start the snapshot" do
        expect(machine).to receive(:action) do |name, opts|
          expect(name).to eq(:snapshot_restore)
          expect(opts[:snapshot_start]).to eq(false)
        end
        subject.execute
      end
    end
  end
end
