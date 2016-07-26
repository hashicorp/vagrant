require_relative "../../../../base"

describe "VagrantPlugins::GuestDarwin::Cap::ChangeHostName" do
  let(:described_class) do
    VagrantPlugins::GuestDarwin::Plugin
      .components
      .guest_capabilities[:darwin]
      .get(:choose_addressable_ip_addr)
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".choose_addressable_ip_addr" do
    let(:possible) { ["1.2.3.4", "5.6.7.8"] }

    it "retrieves the value" do
      comm.stub_command("ping -c1 -t1 5.6.7.8", exit_code: 0)
      result = described_class.choose_addressable_ip_addr(machine, possible)
      expect(result).to eq("5.6.7.8")
    end

    it "returns nil if no ips are found" do
      result = described_class.choose_addressable_ip_addr(machine, [])
      expect(result).to be(nil)
    end
  end
end
