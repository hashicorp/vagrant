require File.expand_path("../../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/guests/windows/cap/reboot")

describe "VagrantPlugins::GuestWindows::Cap::Reboot" do
  let(:described_class) do
    VagrantPlugins::GuestWindows::Plugin.components.guest_capabilities[:windows].get(:wait_for_reboot)
  end
  let(:vm) { double("vm") }
  let(:config) { double("config") }
  let(:machine) { double("machine") }
  let(:communicator) { double(:execute) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:config).and_return(config)
    allow(config).to receive(:vm).and_return(vm)
  end

  describe "winrm communicator" do

    before do
      allow(vm).to receive(:communicator).and_return(:winrm)
    end

    describe ".wait_for_reboot" do
    
      it "runs reboot detect script" do
        expect(communicator).to receive(:execute) do |cmd|
          expect(cmd).to include("SM_SHUTTINGDOWN")
        end.and_return(0)
        described_class.wait_for_reboot(machine)
      end

    end
  end

  describe "ssh communicator" do

    before do
      allow(vm).to receive(:communicator).and_return(:ssh)
    end

    describe ".wait_for_reboot" do
    
      it "runs reboot detect script" do
        expect(communicator).to_not receive(:execute)
        described_class.wait_for_reboot(machine)
      end

    end
  end

end
