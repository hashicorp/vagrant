require_relative "../../../../base"

describe "VagrantPlugins::GuestSmartos::Cap::ChangeHostName" do
  let(:caps) do
    VagrantPlugins::GuestSmartos::Plugin
        .components
        .guest_capabilities[:smartos]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:config) { double("config", smartos: VagrantPlugins::GuestSmartos::Config.new) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
    allow(machine).to receive(:config).and_return(config)
  end

  after do
    comm.verify_expectations!
  end

  describe ".change_host_name" do
    let(:cap) { caps.get(:change_host_name) }

    it "changes the hostname if appropriate" do
      cap.change_host_name(machine, "testhost")

      expect(comm.received_commands[0]).to match(/if hostname | grep 'testhost' ; then/)
      expect(comm.received_commands[0]).to match(/exit 0/)
      expect(comm.received_commands[0]).to match(/fi/)
      expect(comm.received_commands[0]).to match(/if \[ -d \/usbkey \] && \[ "\$\(zonename\)" == "global" \] ; then/)
      expect(comm.received_commands[0]).to match(/pfexec sed -i '' 's\/hostname=\.\*\/hostname=testhost\/' \/usbkey\/config/)
      expect(comm.received_commands[0]).to match(/fi/)
      expect(comm.received_commands[0]).to match(/pfexec echo 'testhost' > \/etc\/nodename/)
      expect(comm.received_commands[0]).to match(/pfexec hostname testhost/)
    end
  end
end
