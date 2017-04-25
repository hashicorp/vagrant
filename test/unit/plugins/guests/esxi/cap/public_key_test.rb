require_relative "../../../../base"

describe "VagrantPlugins::GuestEsxi::Cap::PublicKey" do
  let(:caps) do
    VagrantPlugins::GuestEsxi::Plugin
      .components
      .guest_capabilities[:esxi]
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
      expect(comm.received_commands[0]).to match(/SSH_DIR=".*"/)
      expect(comm.received_commands[0]).to match(/mkdir -p "\${SSH_DIR}"/)
      expect(comm.received_commands[0]).to match(/chmod 0700 "\${SSH_DIR}"/)
      expect(comm.received_commands[0]).to match(/cat '\/tmp\/vagrant-(.+)' >> "\${SSH_DIR}\/authorized_keys"/)
      expect(comm.received_commands[0]).to match(/chmod 0600 "\${SSH_DIR}\/authorized_keys"/)
      expect(comm.received_commands[0]).to match(/rm -f '\/tmp\/vagrant-(.+)'/)
    end
  end

  describe ".remove_public_key" do
    let(:cap) { caps.get(:remove_public_key) }

    it "removes the public key" do
      cap.remove_public_key(machine, "ssh-rsa ...")
      expect(comm.received_commands[0]).to match(/SSH_DIR=".*"/)
      expect(comm.received_commands[0]).to match(/grep -v -x -f '\/tmp\/vagrant-(.+)' "\${SSH_DIR}\/authorized_keys" > "\${SSH_DIR}\/authorized_keys\.tmp"/)
      expect(comm.received_commands[0]).to match(/mv "\${SSH_DIR}\/authorized_keys\.tmp" "\${SSH_DIR}\/authorized_keys"/)
      expect(comm.received_commands[0]).to match(/chmod 0600 "\${SSH_DIR}\/authorized_keys"/)
      expect(comm.received_commands[0]).to match(/rm -f '\/tmp\/vagrant-(.+)'/)
    end
  end

end
