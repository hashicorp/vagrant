require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/provider")

describe VagrantPlugins::HyperV::Provider do
  let(:machine) { double("machine") }
  let(:powershell) { double("powershell") }

  subject { described_class.new(machine) }

  before do
    stub_const("Vagrant::Util::PowerShell", powershell)
    powershell.stub(available?: true)
  end

  describe "#initialize" do
    it "raises an exception if powershell is not available" do
      powershell.stub(available?: false)

      expect { subject }.
        to raise_error(VagrantPlugins::HyperV::Errors::PowerShellRequired)
    end
  end
end
