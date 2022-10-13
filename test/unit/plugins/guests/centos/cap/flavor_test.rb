require_relative "../../../../base"

describe "VagrantPlugins::GuestCentos::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestCentos::Plugin
      .components
      .guest_capabilities[:centos]
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
      "CentOS Linux 2.4 release 7" => :centos_7,
      "CentOS Linux release 8.1.1911 (Core)" => :centos_8,

      "CentOS" => :centos,
      "banana" => :centos,
    }.each do |str, expected|
      it "returns #{expected} for #{str}" do
        comm.stub_command("cat /etc/centos-release", stdout: str)
        expect(cap.flavor(machine)).to be(expected)
      end
    end
  end
end
