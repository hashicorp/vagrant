require "tempfile"
require_relative "../../../../base"
require_relative "../../../../../../plugins/communicators/winssh/communicator"

describe "VagrantPlugins::GuestWindows::Cap::RemovePublicKey" do
  let(:caps) do
    VagrantPlugins::GuestWindows::Plugin
      .components
      .guest_capabilities[:windows]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:public_key_insecure){ "ssh-rsa...insecure" }
  let(:public_key_other){ "ssh-rsa...other" }

  let(:auth_keys_check_result){ 1 }

  before do
    @tempfile = Tempfile.new("vagrant-test")
    @tempfile.puts(public_key_insecure)
    @tempfile.puts(public_key_other)
    @tempfile.flush
    @tempfile.rewind
    allow(Tempfile).to receive(:new).and_return(@tempfile)
    allow(comm).to receive(:is_a?).and_return(true)
    allow(machine).to receive(:communicate).and_return(comm)

    allow(comm).to receive(:execute).with(/echo .+/, shell: "cmd").and_yield(:stdout, "TEMP\r\nHOME\r\n")
    allow(comm).to receive(:execute).with(/dir .+\.ssh/, shell: "cmd")
    allow(comm).to receive(:execute).with(/dir .+authorized_keys/, shell: "cmd", error_check: false).and_return(auth_keys_check_result)
  end

  after do
    @tempfile.delete
  end

  describe ".remove_public_key" do
    let(:cap) { caps.get(:remove_public_key) }

    context "when authorized_keys exists on guest" do
      let(:auth_keys_check_result){ 0 }
      before do
        expect(@tempfile).to receive(:delete).and_return(true)
        expect(@tempfile).to receive(:delete).and_call_original
      end

      it "removes the public key" do
        expect(comm).to receive(:download)
        expect(comm).to receive(:upload)
        expect(comm).to receive(:execute).with(/Set-Acl .*/, shell: "powershell")
        cap.remove_public_key(machine, public_key_insecure)
        expect(File.read(@tempfile.path)).to include(public_key_other)
        expect(File.read(@tempfile.path)).to_not include(public_key_insecure)
      end
    end

    context "when authorized_keys does not exist on guest" do
      it "does nothing" do
        expect(comm).to_not receive(:download)
        expect(comm).to receive(:upload)
        expect(comm).to receive(:execute).with(/Set-Acl .*/, shell: "powershell")
        cap.remove_public_key(machine, public_key_insecure)
      end
    end
  end
end
