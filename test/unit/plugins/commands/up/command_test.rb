require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/up/command")

describe VagrantPlugins::CommandUp::Command do
  include_context "unit"

  let(:entry_klass) { Vagrant::MachineIndex::Entry }
  let(:argv)     { [] }
  let(:vagrantfile_content){ "" }
  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile(vagrantfile_content)
    env.create_vagrant_env
  end

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }

  def new_entry(name)
    entry_klass.new.tap do |e|
      e.name = name
      e.vagrantfile_path = "/bar"
    end
  end

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
  end

  context "with no argument" do
    let(:vagrantfile_content){ "Vagrant.configure(2){|config| config.vm.box = 'dummy'}" }

    it "should bring up the default box" do
      batch = double("environment_batch")
      expect(iso_env).to receive(:batch).and_yield(batch)
      expect(batch).to receive(:action).with(anything, :up, anything)
      subject.execute
    end

    context "with VAGRANT_DEFAULT_PROVIDER set" do
      before do
        if ENV["VAGRANT_DEFAULT_PROVIDER"]
          @original_default = ENV["VAGRANT_DEFAULT_PROVIDER"]
        end
        ENV["VAGRANT_DEFAULT_PROVIDER"] = "unknown"
      end
      after do
        if @original_default
          ENV["VAGRANT_DEFAULT_PROVIDER"] = @original_default
        else
          ENV.delete("VAGRANT_DEFAULT_PROVIDER")
        end
      end

      it "should attempt to use dummy provider" do
        expect{ subject.execute }.to raise_error(Vagrant::Errors::ProviderNotFound)
      end

      context "with --provider set" do
        let(:argv){ ["--provider", "dummy"] }

        it "should only use provider explicitly set" do
          batch = double("environment_batch")
          expect(iso_env).to receive(:batch).and_yield(batch)
          expect(batch).to receive(:action).with(anything, :up, anything)
          subject.execute
        end
      end
    end
  end

  context "with a global machine" do
    let(:argv){ ["1234"] }

    it "brings up a vm with an id" do

      global_env = isolated_environment
      global_env.vagrantfile("Vagrant.configure(2){|config| config.vm.box = 'dummy'}")
      global_venv = global_env.create_vagrant_env
      global_machine = global_venv.machine(global_venv.machine_names[0], :dummy)
      global_machine.id = "1234"
      global = new_entry(global_machine.name)
      global.provider = "dummy"
      global.vagrantfile_path = global_env.workdir
      locked = iso_env.machine_index.set(global)
      iso_env.machine_index.release(locked)

      allow(subject).to receive(:with_target_vms) { |&block| block.call global_machine }


      batch = double("environment_batch")
      expect(iso_env).to receive(:batch).and_yield(batch)
      expect(batch).to receive(:action).with(global_machine, :up, anything) do |machine,action,args|
        expect(machine).to be_kind_of(Vagrant::Machine)
        expect(action).to eq(:up)
      end
      subject.execute
    end
  end

  context "with an argument" do
    let(:vagrantfile_content) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.define "app"
          config.vm.define "db"
        end
        VF
    end
    let(:argv){ ["app"] }
    let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

    it "brings up a vm" do
      batch = double("environment_batch")
      expect(iso_env).to receive(:batch).and_yield(batch)
      expect(batch).to receive(:action).with(machine, :up, anything) do |machine,action,args|
        expect(machine).to be_kind_of(Vagrant::Machine)
        expect(action).to eq(:up)
      end
      subject.execute
    end

    context "with an invalid argument" do
      let(:argv){ ["notweb"] }
      it "brings up a vm" do
        expect { subject.execute }.to raise_error(Vagrant::Errors::MachineNotFound)
      end
    end
  end
end
