require_relative "../../../../base"

describe "VagrantPlugins::GuestALT::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestALT::Plugin
      .components
      .guest_capabilities[:alt]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".flavor" do
    let(:cap) { caps.get(:flavor) }

    {
      "ALT Education 8.1" => :alt,
      "ALT Workstation 8.1" => :alt,
      "ALT Workstation K 8.1  (Centaurea Ruthenica)" => :alt,
      "ALT Linux p8 (Hypericum)" => :alt,
      "ALT Sisyphus (unstable) (sisyphus)" => :alt,

      "ALT Linux 6.0.1 Spt  (separator)" => :alt,
      "ALT Linux 7.0.5 School Master" => :alt,
      "ALT starter kit (Hypericum)" => :alt,

      "ALT" => :alt,
    }.each do |str, expected|
      it "returns #{expected} for #{str}" do
        comm.stub_command("cat /etc/altlinux-release", stdout: str)
        expect(cap.flavor(machine)).to be(expected)
      end
    end
  end
end
