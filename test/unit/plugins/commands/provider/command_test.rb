require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/provider/command")

describe VagrantPlugins::CommandProvider::Command do
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
    context "no arguments" do
      it "exits with the provider name" do
        expect(subject.execute).to eq(0)
      end
    end

    context "--usable" do
      let(:argv) { ["--usable"] }

      it "exits 0 if it is usable" do
        expect(subject.execute).to eq(0)
      end

      it "exits 1 if it is not usable" do
        expect(machine.provider.class).to receive(:usable?).and_return(false)
        expect(subject.execute).to eq(1)
      end
    end
  end
end
