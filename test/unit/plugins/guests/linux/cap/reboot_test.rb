require_relative "../../../../base"

require Vagrant.source_root.join("plugins/guests/linux/cap/reboot")

describe "VagrantPlugins::GuestLinux::Cap::Reboot" do
  let(:described_class) do
    VagrantPlugins::GuestLinux::Plugin.components.guest_capabilities[:linux].get(:wait_for_reboot)
  end

  let(:machine) { double("machine") }
  let(:guest) { double("guest") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:ui) { double("ui") }

  context "systemd not enabled" do
    before do
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(machine).to receive(:guest).and_return(guest)
      allow(machine.guest).to receive(:ready?).and_return(true)
      allow(machine).to receive(:ui).and_return(ui)
      allow(ui).to receive(:info)
      allow(communicator).to receive(:test).and_return(false)
    end

    after do
      communicator.verify_expectations!
    end

    describe ".reboot" do
      it "reboots the vm" do
        allow(communicator).to receive(:execute)

        expect(communicator).to receive(:execute).with(/reboot/, nil).and_return(0)
        expect(described_class).to receive(:wait_for_reboot)

        described_class.reboot(machine)
      end

      context "user output" do
        before do
          allow(communicator).to receive(:execute)
          allow(described_class).to receive(:wait_for_reboot)
        end

        after { described_class.reboot(machine) }

        it "sends message to user that guest is rebooting" do
          expect(ui).to receive(:info)
        end
      end
    end

    context "systemd enabled" do
      before do
        allow(machine).to receive(:communicate).and_return(communicator)
        allow(machine).to receive(:guest).and_return(guest)
        allow(machine.guest).to receive(:ready?).and_return(true)
        allow(machine).to receive(:ui).and_return(ui)
        allow(ui).to receive(:info)
        allow(communicator).to receive(:test).and_return(true)
      end

      after do
        communicator.verify_expectations!
      end

      describe ".reboot" do
        it "reboots the vm" do
          allow(communicator).to receive(:execute)

          expect(communicator).to receive(:execute).with(/systemctl reboot/, nil).and_return(0)
          expect(described_class).to receive(:wait_for_reboot)

          described_class.reboot(machine)
        end
      end
    end

    context "reboot configuration" do
      before do
        allow(communicator).to receive(:execute)
        expect(communicator).to receive(:execute).with(/reboot/, nil).and_return(0)
        allow(described_class).to receive(:sleep)
        allow(described_class).to receive(:wait_for_reboot).and_raise(Vagrant::Errors::MachineGuestNotReady)
      end

      describe ".reboot default" do
        it "allows setting a custom max reboot retry duration" do
          max_retries = 26 # initial call + 25 retries since multiple of 5
          expect(described_class).to receive(:wait_for_reboot).exactly(max_retries).times
          expect { described_class.reboot(machine) }.to raise_error(Vagrant::Errors::MachineGuestNotReady)
        end
      end
    end
  end
end
