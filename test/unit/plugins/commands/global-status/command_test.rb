require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/global-status/command")

describe VagrantPlugins::CommandGlobalStatus::Command do
  include_context "unit"

  let(:entry_klass) { Vagrant::MachineIndex::Entry }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  let(:argv)     { [] }


  def new_entry(name)
    entry_klass.new.tap do |e|
      e.name = name
      e.vagrantfile_path = "/bar"
    end
  end

  subject { described_class.new(argv, iso_env) }

  describe "execute" do
    it "succeeds" do
      # Let's put some things in the index
      iso_env.machine_index.set(new_entry("foo"))
      iso_env.machine_index.set(new_entry("bar"))

      expect(subject.execute).to eq(0)
    end
  end
end
