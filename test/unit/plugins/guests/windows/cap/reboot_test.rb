# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/guests/windows/cap/reboot")

describe "VagrantPlugins::GuestWindows::Cap::Reboot" do
  let(:described_class) do
    VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:wait_for_reboot)
  end
  let(:vm) { double("vm") }
  let(:config) { double("config") }
  let(:machine) { double("machine", ui: ui) }
  let(:guest) { double("guest") }
  let(:communicator) { double("communicator") }
  let(:ui) { Vagrant::UI::Silent.new }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:guest).and_return(guest)
    allow(machine.guest).to receive(:ready?).and_return(true)
    allow(machine).to receive(:config).and_return(config)
    allow(config).to receive(:vm).and_return(vm)
  end

  describe ".reboot" do
    before do
      allow(vm).to receive(:communicator).and_return(:winrm)
    end

    it "reboots the vm" do
      allow(communicator).to receive(:execute)

      expect(communicator).to receive(:test).with(/# Function/, { error_check: false, shell: :powershell }).and_return(0)
      expect(communicator).to receive(:execute).with(/shutdown/, { shell: :powershell }).and_return(0)
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
        expect(communicator).to receive(:test).and_return(true)
        expect(ui).to receive(:info).and_call_original
      end
    end

    context "with exceptions while waiting for reboot" do
      before { allow(described_class).to receive(:sleep) }

      it "should retry on any standard error" do
        allow(communicator).to receive(:execute)

        expect(communicator).to receive(:test).with(/# Function/, { error_check: false, shell: :powershell }).and_return(0)
        expect(communicator).to receive(:execute).with(/shutdown/, { shell: :powershell }).and_return(0)
        expect(described_class).to receive(:wait_for_reboot).and_raise(StandardError)
        expect(described_class).to receive(:wait_for_reboot)

        described_class.reboot(machine)
      end

      it "should not retry when exception is not a standard error" do
        allow(communicator).to receive(:execute)

        expect(communicator).to receive(:test).with(/# Function/, { error_check: false, shell: :powershell }).and_return(0)
        expect(communicator).to receive(:execute).with(/shutdown/, { shell: :powershell }).and_return(0)
        expect(described_class).to receive(:wait_for_reboot).and_raise(Exception)

        expect { described_class.reboot(machine) }.to raise_error(Exception)
      end
    end
  end

  describe "winrm communicator" do
    before do
      allow(vm).to receive(:communicator).and_return(:winrm)
    end

    describe ".wait_for_reboot" do
      it "runs reboot detect script" do
        expect(communicator).to receive(:execute).with(/# Function/, { error_check: false, shell: :powershell }).and_return(0)
        allow(communicator).to receive(:execute)

        described_class.wait_for_reboot(machine)
      end

      it "fixes symlinks to network shares" do
        allow(communicator).to receive(:execute).and_return(0)
        expect(communicator).to receive(:execute).with('net use', { error_check: false, shell: :powershell })

        described_class.wait_for_reboot(machine)
      end
    end
  end

  describe "ssh communicator" do
    before do
      allow(vm).to receive(:communicator).and_return(:ssh)
    end

    describe ".wait_for_reboot" do
      it "does execute Windows reboot detect script" do
        expect(communicator).to receive(:execute).with(/# Function/, { error_check: false, shell: :powershell }).and_return(0)
        expect(communicator).to receive(:execute).with('net use', { error_check: false, shell: :powershell })
        described_class.wait_for_reboot(machine)
      end
    end
  end

  context "reboot configuration" do
    before do
      allow(communicator).to receive(:execute)
      expect(communicator).to receive(:test).with(/# Function/, { error_check: false, shell: :powershell }).and_return(0)
      expect(communicator).to receive(:execute).with(/shutdown/, { shell: :powershell }).and_return(0)
      allow(described_class).to receive(:sleep)
      allow(described_class).to receive(:wait_for_reboot).and_raise(StandardError)
    end

    context "default retry duration value" do
      let(:max_retries) { (described_class::DEFAULT_MAX_REBOOT_RETRY_DURATION / described_class::WAIT_SLEEP_TIME) + 2 }

      it "should receive expected number of wait_for_reboot calls" do
        expect(described_class).to receive(:wait_for_reboot).exactly(max_retries).times
        expect { described_class.reboot(machine) }.to raise_error(StandardError)
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
        expect { described_class.reboot(machine) }.to raise_error(StandardError)
      end
    end
  end
end
