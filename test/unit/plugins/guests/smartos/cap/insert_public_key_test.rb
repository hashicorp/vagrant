require_relative "../../../../base"

describe "VagrantPlugins::GuestSmartos::Cap::InsertPublicKey" do
  let(:caps) do
    VagrantPlugins::GuestSmartos::Plugin
        .components
        .guest_capabilities[:smartos]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".insert_public_key" do
    let(:cap) { caps.get(:insert_public_key) }

    it "inserts the public key" do
      cap.insert_public_key(machine, "ssh-rsa ...")

      expect(comm.received_commands[0]).to match(/if \[ -d \/usbkey \] && \[ "\$\(zonename\)" == "global" \] ; then/)
      expect(comm.received_commands[0]).to match(/printf 'ssh-rsa ...\\n' >> \/usbkey\/config.inc\/authorized_keys/)
      expect(comm.received_commands[0]).to match(/cp \/usbkey\/config.inc\/authorized_keys ~\/.ssh\/authorized_keys/)
      expect(comm.received_commands[0]).to match(/else/)
      expect(comm.received_commands[0]).to match(/mkdir -p ~\/.ssh/)
      expect(comm.received_commands[0]).to match(/chmod 0700 ~\/.ssh/)
      expect(comm.received_commands[0]).to match(/printf 'ssh-rsa ...\\n' >> ~\/.ssh\/authorized_keys/)
      expect(comm.received_commands[0]).to match(/chmod 0600 ~\/.ssh\/authorized_keys/)
      expect(comm.received_commands[0]).to match(/fi/)
    end
  end
end
