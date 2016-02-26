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
    machine.stub(id: "foo")
    platform.stub(windows?: true)
    platform.stub(windows_admin?: true)
    platform.stub(windows_hyperv_admin?: true)
    powershell.stub(available?: true)
  end

  describe ".usable?" do
    subject { described_class }

    it "returns false if not windows" do
      platform.stub(windows?: false)
      expect(subject).to_not be_usable
    end

    it "returns false if neither an admin nor a hyper-v admin" do
      platform.stub(windows_admin?: false)
      platform.stub(windows_hyperv_admin?: false)
      expect(subject).to_not be_usable
    end

    it "returns true if not an admin but is a hyper-v admin" do
      platform.stub(windows_admin?: false)
      platform.stub(windows_hyperv_admin?: true)
      expect(subject).to be_usable
    end

    it "returns false if powershell is not available" do
      powershell.stub(available?: false)
      expect(subject).to_not be_usable
    end

    it "raises an exception if not windows" do
      platform.stub(windows?: false)

      expect { subject.usable?(true) }.
        to raise_error(VagrantPlugins::HyperV::Errors::WindowsRequired)
    end

    it "raises an exception if neither an admin nor a hyper-v admin" do
      platform.stub(windows_admin?: false)
      platform.stub(windows_hyperv_admin?: false)

      expect { subject.usable?(true) }.
        to raise_error(VagrantPlugins::HyperV::Errors::AdminRequired)
    end

    it "raises an exception if neither an admin nor a hyper-v admin" do
      platform.stub(windows_admin?: false)
      platform.stub(windows_hyperv_admin?: false)

      expect { subject.usable?(true) }.
        to raise_error(VagrantPlugins::HyperV::Errors::AdminRequired)
    end

    it "raises an exception if powershell is not available" do
      powershell.stub(available?: false)

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
      machine.stub(id: nil)

      expect(subject.state.id).to eq(:not_created)
    end

    it "calls an action to determine the ID" do
      machine.stub(id: "foo")
      expect(machine).to receive(:action).with(:read_state).
        and_return({ machine_state_id: :bar })

      expect(subject.state.id).to eq(:bar)
    end
  end
end
