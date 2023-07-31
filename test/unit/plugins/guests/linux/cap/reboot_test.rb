# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/guests/linux/cap/reboot")

describe "VagrantPlugins::GuestLinux::Cap::Reboot" do
  let(:described_class) do
    VagrantPlugins::GuestLinux::Plugin.components.guest_capabilities[:linux].get(:wait_for_reboot)
  end

  let(:machine) { double("machine", guest: guest) }
  let(:guest) { double("guest") }
  let(:communicator) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:ui) { Vagrant::UI::Silent.new }

  context "systemd not enabled" do
    before do
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(machine).to receive(:guest).and_return(guest)
      allow(machine.guest).to receive(:ready?).and_return(true)
      allow(machine).to receive(:ui).and_return(ui)
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
          expect(ui).to receive(:info).and_call_original
        end
      end
    end

    context "systemd enabled" do
      before do
        allow(machine).to receive(:communicate).and_return(communicator)
        allow(machine).to receive(:guest).and_return(guest)
        allow(machine.guest).to receive(:ready?).and_return(true)
        allow(machine).to receive(:ui).and_return(ui)
        allow(communicator).to receive(:test).and_return(true)
      end

      after do
        communicator.verify_expectations!
      end

      it "reboots the vm" do
        allow(communicator).to receive(:execute)

        expect(communicator).to receive(:execute).with(/systemctl reboot/, nil).and_return(0)
        expect(described_class).to receive(:wait_for_reboot)

        described_class.reboot(machine)
      end
    end

    context "reboot configuration" do
      before do
        allow(communicator).to receive(:execute)
        expect(communicator).to receive(:execute).with(/reboot/, nil).and_return(0)
        allow(described_class).to receive(:sleep).and_return(described_class::WAIT_SLEEP_TIME)
        allow(described_class).to receive(:wait_for_reboot).and_raise(Vagrant::Errors::MachineGuestNotReady)
      end

      context "default retry duration value" do
        let(:max_retries) { (described_class::DEFAULT_MAX_REBOOT_RETRY_DURATION / described_class::WAIT_SLEEP_TIME) + 2 }

        it "should receive expected number of wait_for_reboot calls" do
          expect(described_class).to receive(:wait_for_reboot).exactly(max_retries).times
          expect { described_class.reboot(machine) }.to raise_error(Vagrant::Errors::MachineGuestNotReady)
        end
      end

      context "with custom retry duration value" do
        let(:duration) { 10 }
        let(:max_retries) { (duration / described_class::WAIT_SLEEP_TIME) + 2 }

        before do
          expect(ENV).to receive(:fetch).with("VAGRANT_MAX_REBOOT_RETRY_DURATION", anything).and_return(duration)
        end

        it "should receive expected number of wait_for_reboot calls" do
          expect(described_class).to receive(:wait_for_reboot).exactly(max_retries).times
          expect { described_class.reboot(machine) }.to raise_error(Vagrant::Errors::MachineGuestNotReady)
        end
      end
    end
  end

  describe ".wait_for_reboot" do
    before do
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(communicator).to receive(:execute).and_return(0)
      allow(guest).to receive(:ready?).and_return(false)
    end

    context "when guest is ready" do
      before { expect(guest).to receive(:ready?).and_return(true) }

      it "should sleep" do
        expect(described_class).to receive(:sleep).with(10)
        described_class.wait_for_reboot(machine)
      end

      context "when check script fails" do
        before { expect(communicator).to receive(:execute).with(/grep/, any_args).and_return(1) }

        it "should not sleep" do
          expect(described_class).not_to receive(:sleep)
          described_class.wait_for_reboot(machine)
        end
      end

      context "when communicator raises an error" do
        let(:error) { Class.new(StandardError) }

        before do
          expect(communicator).to receive(:execute).with(/grep/, any_args).and_raise(error)
          expect(guest).to receive(:ready?).and_return(true)
        end

        it "should sleep once for exception and once for the guest being ready" do
          expect(described_class).to receive(:sleep).with(10).twice
          described_class.wait_for_reboot(machine)
        end

        context "when communicator raises error more than once" do
          before { expect(communicator).to receive(:execute).with(/grep/, any_args).and_raise(error) }

          it "should sleep once and raise error" do
            expect(described_class).to receive(:sleep).with(10)
            expect { described_class.wait_for_reboot(machine) }.to raise_error(error)
          end
        end
      end
    end

    context "when guest is not ready" do
      before { expect(guest).to receive(:ready?).and_return(false) }

      it "should not sleep" do
        expect(described_class).not_to receive(:sleep)
        described_class.wait_for_reboot(machine)
      end
    end
  end
end
