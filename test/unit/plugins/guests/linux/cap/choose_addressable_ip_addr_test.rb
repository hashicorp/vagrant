require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::ChooseAddressableIPAddr" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
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
    let(:cap) { caps.get(:choose_addressable_ip_addr) }

    it "returns the first matching IP address" do
      possible = ["1.2.3.4", "5.6.7.8"]
      possible.each do |ip|
        comm.stub_command("ping -c1 -w1 -W1 #{ip}", exit_code: 0)
      end
      result = cap.choose_addressable_ip_addr(machine, possible)
      expect(result).to eq("1.2.3.4")
    end

    it "returns nil when there are no matches" do
      result = cap.choose_addressable_ip_addr(machine, [])
      expect(result).to be(nil)
    end
  end
end
