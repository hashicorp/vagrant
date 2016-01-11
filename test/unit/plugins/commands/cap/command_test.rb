require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/cap/command")

describe VagrantPlugins::CommandCap::Command do
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
    context "--check provider foo (exists)" do
      let(:argv) { ["--check", "provider", "foo"] }
      let(:cap) { Class.new }

      before do
        register_plugin do |p|
          p.provider_capability(:dummy, :foo) { cap }
        end
      end

      it "exits with 0 if it exists" do
        expect(subject.execute).to eq(0)
      end
    end

    context "--check provider foo (doesn't exists)" do
      let(:argv) { ["--check", "provider", "foo"] }

      it "exits with 1" do
        expect(subject.execute).to eq(1)
      end
    end
  end
end
