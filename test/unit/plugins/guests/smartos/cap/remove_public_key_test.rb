require_relative "../../../../base"

describe "VagrantPlugins::GuestSmartos::Cap::RemovePublicKey" do
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

  describe ".remove_public_key" do
    let(:cap) { caps.get(:remove_public_key) }

    it "removes the public key" do
      cap.remove_public_key(machine, "ssh-rsa keyvalue comment")
      expect(comm.received_commands[0]).to match(/if test -f \/usbkey\/config.inc\/authorized_keys ; then/)
      expect(comm.received_commands[0]).to match(/sed -i '' '\/\^.*ssh-rsa keyvalue comment.*\$\/d' \/usbkey\/config.inc\/authorized_keys/)
      expect(comm.received_commands[0]).to match(/fi/)
      expect(comm.received_commands[0]).to match(/if test -f ~\/.ssh\/authorized_keys ; then/)
      expect(comm.received_commands[0]).to match(/sed -i '' '\/\^.*ssh-rsa keyvalue comment.*\$\/d' ~\/.ssh\/authorized_keys/)
      expect(comm.received_commands[0]).to match(/fi/)
    end
  end
end
