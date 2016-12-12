require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::Port" do
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

  describe ".port_open_check" do
    let(:cap) { caps.get(:port_open_check) }

    it "checks if the port is open" do
      port = 8080
      comm.expect_command("nc -z -w2 127.0.0.1 #{port}")
      cap.port_open_check(machine, port)
    end
  end
end
