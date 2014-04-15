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

  describe "execute with no args" do
    it "succeeds" do
      # Let's put some things in the index
      iso_env.machine_index.set(new_entry("foo"))
      iso_env.machine_index.set(new_entry("bar"))

      expect(subject.execute).to eq(0)
    end
  end

  describe "execute with --prune" do
    let(:argv) { ["--prune"] }

    it "removes invalid entries" do
      # Invalid entry because vagrantfile path is gone
      entryA = new_entry("A")
      entryA.vagrantfile_path = "/i/dont/exist"
      locked = iso_env.machine_index.set(entryA)
      iso_env.machine_index.release(locked)

      # Invalid entry because that specific machine doesn't exist anymore.
      entryB_env = isolated_environment
      entryB_env.vagrantfile("")
      entryB = new_entry("B")
      entryB.vagrantfile_path = entryB_env.workdir
      locked = iso_env.machine_index.set(entryB)
      iso_env.machine_index.release(locked)

      # Valid entry because the machine does exist
      entryC_env = isolated_environment
      entryC_env.vagrantfile("")
      entryC_venv = entryC_env.create_vagrant_env
      entryC_machine = entryC_venv.machine(entryC_venv.machine_names[0], :dummy)
      entryC_machine.id = "foo"
      entryC = new_entry(entryC_machine.name)
      entryC.provider = "dummy"
      entryC.vagrantfile_path = entryC_env.workdir
      locked = iso_env.machine_index.set(entryC)
      iso_env.machine_index.release(locked)

      expect(subject.execute).to eq(0)

      # Reload the data and see that we got things correct
      entries = []
      iso_env.machine_index.each(true) { |e| entries << e }

      expect(entries.length).to eq(1)
      expect(entries[0].name).to eq(entryC_machine.name.to_s)
    end
  end
end
