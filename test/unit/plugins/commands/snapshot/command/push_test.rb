require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/snapshot/command/push")

describe VagrantPlugins::CommandSnapshot::Command::Push do
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
    it "calls snapshot_save with a random snapshot name" do
      machine.id = "foo"

      expect(machine).to receive(:action) do |name, opts|
        expect(name).to eq(:snapshot_save)
        expect(opts[:snapshot_name]).to match(/^push_/)
      end

      expect(subject.execute).to eq(0)
    end

    it "doesn't snapshot a non-existent machine" do
      machine.id = nil

      expect(machine).to_not receive(:action)
      expect(subject.execute).to eq(0)
    end
  end
end
