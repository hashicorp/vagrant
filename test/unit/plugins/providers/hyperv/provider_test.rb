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
    platform.stub(windows?: true)
    platform.stub(windows_admin?: true)
    powershell.stub(available?: true)
  end

  describe "#initialize" do
    it "raises an exception if not windows" do
      platform.stub(windows?: false)

      expect { subject }.
        to raise_error(VagrantPlugins::HyperV::Errors::WindowsRequired)
    end

    it "raises an exception if not an admin" do
      platform.stub(windows_admin?: false)

      expect { subject }.
        to raise_error(VagrantPlugins::HyperV::Errors::AdminRequired)
    end

    it "raises an exception if powershell is not available" do
      powershell.stub(available?: false)

      expect { subject }.
        to raise_error(VagrantPlugins::HyperV::Errors::PowerShellRequired)
    end
  end

  describe "#driver" do
    it "is initialized" do
      expect(subject.driver).to be_kind_of(VagrantPlugins::HyperV::Driver)
    end
  end
end
