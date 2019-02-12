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
  let(:ui) { double("ui") }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:guest).and_return(guest)
    allow(machine.guest).to receive(:ready?).and_return(true)
    allow(machine).to receive(:config).and_return(config)
    allow(config).to receive(:vm).and_return(vm)
    allow(ui).to receive(:info)
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
        expect(ui).to receive(:info)
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
end
