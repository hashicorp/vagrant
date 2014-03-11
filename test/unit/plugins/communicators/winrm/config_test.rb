require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/config")

describe VagrantPlugins::CommunicatorWinRM::Config do
  let(:machine) { double("machine") }

  subject { described_class.new }

  it "is valid by default" do
    subject.finalize!
    result = subject.validate(machine)
    expect(result["WinRM"]).to be_empty
  end
end
