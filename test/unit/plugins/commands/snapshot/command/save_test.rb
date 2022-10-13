require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/snapshot/command/save")

describe VagrantPlugins::CommandSnapshot::Command::Save do
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

  let(:argv) { [] }

  subject { described_class.new(argv, iso_env) }

  before do
    allow(machine.provider).to receive(:capability).with(:snapshot_list).
      and_return([])

    allow(machine.provider).to receive(:capability?).with(:snapshot_list).
      and_return(true)

    allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
  end

  describe "execute" do
    context "with no arguments" do
      it "shows help" do
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::CLIInvalidUsage)
      end
    end

    context "with an unsupported provider" do
      let(:argv)     { ["test"] }

      before do
        allow(machine.provider).to receive(:capability?).with(:snapshot_list).
          and_return(false)
      end

      it "raises an exception" do
        machine.id = "foo"
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::SnapshotNotSupported)
      end
    end

    context "with a snapshot name given" do
      let(:argv)     { ["test"] }
      it "calls snapshot_save with a snapshot name" do
        machine.id = "foo"

        expect(machine).to receive(:action) do |name, opts|
          expect(name).to eq(:snapshot_save)
          expect(opts[:snapshot_name]).to eq("test")
        end

        expect(subject.execute).to eq(0)
      end

      it "doesn't snapshot a non-existent machine" do
        machine.id = nil

        expect(subject).to receive(:with_target_vms){}

        expect(machine).to_not receive(:action)
        expect(subject.execute).to eq(0)
      end
    end

    context "with a snapshot guest and name given" do
      let(:argv)     { ["foo", "backup"] }
      it "calls snapshot_save with a snapshot name" do
        machine.id = "foo"

        expect(machine).to receive(:action) do |name, opts|
          expect(name).to eq(:snapshot_save)
          expect(opts[:snapshot_name]).to eq("backup")
        end

        expect(subject.execute).to eq(0)
      end

      it "doesn't snapshot a non-existent machine" do
        machine.id = nil

        expect(machine).to_not receive(:action)
        expect(subject.execute).to eq(0)
      end
    end

    context "with a duplicate snapshot name given and no force flag" do
      let(:argv)     { ["test"] }

      it "fails to take a snapshot and prints a warning to the user" do
        machine.id = "fool"

        allow(machine.provider).to receive(:capability).with(:snapshot_list).
          and_return(["test"])

        expect(machine).to_not receive(:action)
        expect { subject.execute }.
          to raise_error(Vagrant::Errors::SnapshotConflictFailed)
      end
    end

    context "with a duplicate snapshot name given and a force flag" do
      let(:argv)     { ["test", "--force"] }

      it "deletes the existing snapshot and takes a new one" do
        machine.id = "foo"

        allow(machine.provider).to receive(:capability).with(:snapshot_list).
          and_return(["test"])

        expect(machine).to receive(:action).with(:snapshot_delete, snapshot_name: "test")
        expect(machine).to receive(:action).with(:snapshot_save, snapshot_name: "test")

        expect(subject.execute).to eq(0)
      end
    end
  end
end
