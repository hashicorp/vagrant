require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/provider")

describe VagrantPlugins::HyperV::Provider do
  let(:machine) { double("machine") }
  let(:platform)   { double("platform") }
  let(:powershell) { double("powershell") }

  subject { described_class.new(machine) }

  before do
    stub_const("Vagrant::Util::Platform", platform)
    stub_const("Vagrant::Util::PowerShell", powershell)
    allow(machine).to receive(:id).and_return("foo")
    allow(platform).to receive(:windows?).and_return(true)
    allow(platform).to receive(:windows_admin?).and_return(true)
    allow(platform).to receive(:windows_hyperv_admin?).and_return(true)
    allow(powershell).to receive(:available?).and_return(true)
  end

  describe ".usable?" do
    subject { described_class }

    it "returns false if not windows" do
      allow(platform).to receive(:windows?).and_return(false)
      expect(subject).to_not be_usable
    end

    it "returns false if neither an admin nor a hyper-v admin" do
      allow(platform).to receive(:windows_admin?).and_return(false)
      allow(platform).to receive(:windows_hyperv_admin?).and_return(false)
      expect(subject).to_not be_usable
    end

    it "returns true if not an admin but is a hyper-v admin" do
      allow(platform).to receive(:windows_admin?).and_return(false)
      allow(platform).to receive(:windows_hyperv_admin?).and_return(true)
      expect(subject).to be_usable
    end

    it "returns false if powershell is not available" do
      allow(powershell).to receive(:available?).and_return(false)
      expect(subject).to_not be_usable
    end

    it "raises an exception if not windows" do
      allow(platform).to receive(:windows?).and_return(false)

      expect { subject.usable?(true) }.
        to raise_error(VagrantPlugins::HyperV::Errors::WindowsRequired)
    end

    it "raises an exception if neither an admin nor a hyper-v admin" do
      allow(platform).to receive(:windows_admin?).and_return(false)
      allow(platform).to receive(:windows_hyperv_admin?).and_return(false)

      expect { subject.usable?(true) }.
        to raise_error(VagrantPlugins::HyperV::Errors::AdminRequired)
    end

    it "raises an exception if neither an admin nor a hyper-v admin" do
      allow(platform).to receive(:windows_admin?).and_return(false)
      allow(platform).to receive(:windows_hyperv_admin?).and_return(false)

      expect { subject.usable?(true) }.
        to raise_error(VagrantPlugins::HyperV::Errors::AdminRequired)
    end

    it "raises an exception if powershell is not available" do
      allow(powershell).to receive(:available?).and_return(false)

      expect { subject.usable?(true) }.
        to raise_error(VagrantPlugins::HyperV::Errors::PowerShellRequired)
    end
  end

  describe "#driver" do
    it "is initialized" do
      expect(subject.driver).to be_kind_of(VagrantPlugins::HyperV::Driver)
    end
  end

  describe "#state" do
    it "returns not_created if no ID" do
      allow(machine).to receive(:id).and_return(nil)

      expect(subject.state.id).to eq(:not_created)
    end

    it "calls an action to determine the ID" do
      allow(machine).to receive(:id).and_return("foo")
      expect(machine).to receive(:action).with(:read_state).
        and_return({ machine_state_id: :bar })

      expect(subject.state.id).to eq(:bar)
    end
  end
end
