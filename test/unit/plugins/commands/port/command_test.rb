require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/port/command")

describe VagrantPlugins::CommandPort::Command do
  include_context "unit"
  include_context "command plugin helpers"

  let(:iso_env) { isolated_environment }
  let(:env) do
    iso_env.vagrantfile(<<-VF)
      Vagrant.configure("2") do |config|
        config.vm.box = "hashicorp/precise64"
      end
    VF
    iso_env.create_vagrant_env
  end

  let(:state) { double(:state, id: :running) }

  let(:machine) { env.machine(env.machine_names[0], :dummy) }

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/commands/port/locales/en.yml")
    I18n.reload!
  end

  subject { described_class.new([], env) }

  before do
    allow(machine).to receive(:state).and_return(state)
    allow(subject).to receive(:with_target_vms) { |&block| block.call(machine) }
  end

  describe "#execute" do
    it "validates the configuration" do
      iso_env.vagrantfile <<-EOH
        Vagrant.configure("2") do |config|
          config.vm.box = "hashicorp/precise64"

          config.push.define "noop" do |push|
            push.bad = "ham"
          end
        end
      EOH

      subject = described_class.new([], iso_env.create_vagrant_env)

      expect { subject.execute }.to raise_error(Vagrant::Errors::ConfigInvalid) { |err|
        expect(err.message).to include("The following settings shouldn't exist: bad")
      }
    end

    it "ensures the vm is running" do
      allow(state).to receive(:id).and_return(:stopped)
      expect(env.ui).to receive(:error).with(any_args) { |message, _|
        expect(message).to include("does not support listing forwarded ports")
      }

      expect(subject.execute).to eq(1)
    end

    it "shows a friendly error when the capability is not supported" do
      allow(machine.provider).to receive(:capability?).and_return(false)
      expect(env.ui).to receive(:error).with(any_args) { |message, _|
        expect(message).to include("does not support listing forwarded ports")
      }

      expect(subject.execute).to eq(1)
    end

    it "returns a friendly message when there are no forwarded ports" do
      allow(machine.provider).to receive(:capability?).and_return(true)
      allow(machine.provider).to receive(:capability).with(:forwarded_ports)
        .and_return([])

      expect(env.ui).to receive(:info).with(any_args) { |message, _|
        expect(message).to include("there are no forwarded ports")
      }

      expect(subject.execute).to eq(0)
    end

    it "returns the list of ports" do
      allow(machine.provider).to receive(:capability?).and_return(true)
      allow(machine.provider).to receive(:capability).with(:forwarded_ports)
        .and_return([[2222,22], [1111,11]])

      output = ""
      allow(env.ui).to receive(:info) do |data|
        output << data
      end

      expect(subject.execute).to eq(0)

      expect(output).to include("forwarded ports for the machine")
      expect(output).to include("22 (guest) => 2222 (host)")
      expect(output).to include("11 (guest) => 1111 (host)")
    end

    it "prints the matching host port when --guest is given" do
      argv = ["--guest", "22"]
      subject = described_class.new(argv, env)

      allow(machine.provider).to receive(:capability?).and_return(true)
      allow(machine.provider).to receive(:capability).with(:forwarded_ports)
        .and_return([[2222,22]])

      output = ""
      allow(env.ui).to receive(:info) do |data|
        output << data
      end

      expect(subject.execute).to eq(0)

      expect(output).to eq("2222")
    end

    it "returns an error with no port is mapped to the --guest option" do
      argv = ["--guest", "80"]
      subject = described_class.new(argv, env)

      allow(machine.provider).to receive(:capability?).and_return(true)
      allow(machine.provider).to receive(:capability).with(:forwarded_ports)
        .and_return([[2222,22]])

      output = ""
      allow(env.ui).to receive(:error) do |data|
        output << data
      end

      expect(subject.execute).to_not eq(0)

      expect(output).to include("not currently mapping port 80")
    end
  end
end
