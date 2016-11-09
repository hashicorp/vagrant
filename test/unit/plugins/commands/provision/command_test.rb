require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/provision/command")

describe VagrantPlugins::CommandProvision::Command do
  include_context "unit"
  include_context "command plugin helpers"

  let(:iso_env) { isolated_environment }
  let(:env) do
    iso_env.vagrantfile(<<-VF)
      Vagrant.configure("2") do |config|
        config.vm.box = "hashicorp/precise64"
        config.vm.provision "shell", inline: "echo hi"
      end
    VF
    iso_env.create_vagrant_env
  end
  let(:machine_state){ double("machine_state") }
  let(:machine){ double("machine", state: machine_state) }

  let(:argv){ [] }

  subject { described_class.new(argv, env) }

  describe "#execute" do
    before do
      allow(subject).to receive(:with_target_vms).and_yield(machine)
    end

    it "validates provisions default machine" do
      expect(machine).to receive(:action).with(:provision, {})
      subject.execute
    end

    context "with automatic up option enabled" do
      let(:argv){ ['--up'] }

      context "with machine in 'not_created' state" do
        before do
          allow(machine_state).to receive(:id).and_return(:not_created)
          expect(machine).to receive(:action).with(:provision, :auto_up => true)
        end

        it "starts the machine before provision" do
          expect(machine).to receive(:action).with(:up)
          subject.execute
        end
      end

      context "with machine in 'poweroff' state" do
        before do
          allow(machine_state).to receive(:id).and_return(:poweroff)
          expect(machine).to receive(:action).with(:provision, :auto_up => true)
        end

        it "creates the machine before provision" do
          expect(machine).to receive(:action).with(:up)
          subject.execute
        end
      end

      context "with machine in 'paused' state" do
        before do
          allow(machine_state).to receive(:id).and_return(:paused)
          expect(machine).to receive(:action).with(:provision, :auto_up => true)
        end

        it "resumes the machine before provision" do
          expect(machine).to receive(:action).with(:resume)
          subject.execute
        end
      end

      context "with machine in 'saved' state" do
        before do
          allow(machine_state).to receive(:id).and_return(:paused)
          expect(machine).to receive(:action).with(:provision, :auto_up => true)
        end

        it "resumes the machine before provision" do
          expect(machine).to receive(:action).with(:resume)
          subject.execute
        end
      end

      context "with the machine in 'running' state" do
        before do
          allow(machine_state).to receive(:id).and_return(:running)
          expect(machine).to receive(:action).with(:provision, :auto_up => true)
        end

        it "does not change machine state before provision" do
          subject.execute
        end
      end

      context "with machine in busy state" do
        before do
          allow(machine_state).to receive(:id).and_return(:halting)
        end

        it "does not change machine state before provision" do
          expect(machine).to receive(:name).and_return('default')
          expect(machine_state).to receive(:short_description).and_return('Halting')
          expect{ subject.execute }.to raise_error Vagrant::Errors::ProvisionAutoUpFailure
        end
      end
    end
  end
end
