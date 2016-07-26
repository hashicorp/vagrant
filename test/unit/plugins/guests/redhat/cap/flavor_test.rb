require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
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
      "CentOS Linux 2.4 release 7" => :rhel_7,
      "Red Hat Enterprise Linux release 7" => :rhel_7,
      "Scientific Linux release 7" => :rhel_7,
      "CloudLinux release 7.2 (Valeri Kubasov)" => :rhel_7,

      "CentOS" => :rhel,
      "RHEL 6" => :rhel,
      "banana" => :rhel,
    }.each do |str, expected|
      it "returns #{expected} for #{str}" do
        comm.stub_command("cat /etc/redhat-release", stdout: str)
        expect(cap.flavor(machine)).to be(expected)
      end
    end
  end
end
