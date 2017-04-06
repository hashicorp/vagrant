require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/snapshot/command/list")

describe VagrantPlugins::CommandSnapshot::Command::List do
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
    allow(machine.provider).to receive(:capability?).with(:snapshot_list).
      and_return(true)

    allow(machine.provider).to receive(:capability).with(:snapshot_list).
      and_return([])

    allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
  end

  describe "execute" do
    context "with an unsupported provider" do
      let(:argv)     { ["foo"] }

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

    context "with a vm given" do
      let(:argv)     { ["foo"] }

      it "prints a message if the vm does not exist" do
        machine.id = nil

        expect(iso_env.ui).to receive(:info).with("==> default: VM not created. Moving on...", anything)
          .and_return({})
        expect(machine).to_not receive(:action)
        expect(subject.execute).to eq(0)
      end

      it "prints a message if no snapshots have been taken" do
        machine.id = "foo"

        expect(iso_env.ui).to receive(:output)
          .with(/No snapshots have been taken yet!/, anything)
        expect(subject.execute).to eq(0)
      end

      it "prints a list of snapshots" do
        machine.id = "foo"

        allow(machine.provider).to receive(:capability).with(:snapshot_list).
          and_return(["foo", "bar", "baz"])

        expect(iso_env.ui).to receive(:output).with(/foo/, anything)
        expect(iso_env.ui).to receive(:output).with(/bar/, anything)
        expect(iso_env.ui).to receive(:output).with(/baz/, anything)
        expect(subject.execute).to eq(0)
      end
    end
  end
end
