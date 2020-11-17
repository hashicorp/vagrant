require_relative "../../../../base"

describe "VagrantPlugins::GuestDarwin::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestDarwin::Plugin
      .components
      .guest_capabilities[:darwin]
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
      "11.0.1" => :big_sur,
      "11.0.11" => :big_sur,
      "11.0" => :big_sur,
      "10.15.123" => :catalina,
      "" => :darwin,
      "10.14.1" => :darwin,
    }.each do |str, expected|
      it "returns #{expected} for #{str}" do
        comm.stub_command("sw_vers -productVersion", stdout: str)
        expect(cap.flavor(machine)).to be(expected)
      end
    end

    it "contines if sw_vers is not available" do 
      comm.stub_command("sw_vers -productVersion", stdout: "something!")
      expect(cap.flavor(machine)).to be(:darwin)
    end
  end
end
