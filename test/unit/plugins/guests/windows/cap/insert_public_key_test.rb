require "tempfile"
require_relative "../../../../base"
require_relative "../../../../../../plugins/communicators/winssh/communicator"

describe "VagrantPlugins::GuestWindows::Cap::InsertPublicKey" do
  let(:caps) do
    VagrantPlugins::GuestWindows::Plugin
      .components
      .guest_capabilities[:windows]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }
  let(:auth_keys_check_result){ 1 }

  before do
    @tempfile = Tempfile.new("vagrant-test")
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

  describe ".insert_public_key" do
    let(:cap) { caps.get(:insert_public_key) }

    context "when authorized_keys exists on guest" do
      let(:auth_keys_check_result){ 0 }
      before do
        expect(@tempfile).to receive(:delete).and_return(true)
        expect(@tempfile).to receive(:delete).and_call_original
      end

      it "inserts the public key" do
        expect(comm).to receive(:download)
        expect(comm).to receive(:upload)
        expect(comm).to receive(:execute).with(/Set-Acl .*/, shell: "powershell")
        cap.insert_public_key(machine, "ssh-rsa ...")
        expect(File.read(@tempfile.path)).to include("ssh-rsa ...")
      end
    end

    context "when authorized_keys does not exist on guest" do
      before do
        expect(@tempfile).to receive(:delete).and_return(true)
        expect(@tempfile).to receive(:delete).and_call_original
      end

      it "inserts the public key" do
        expect(comm).to_not receive(:download)
        expect(comm).to receive(:upload)
        expect(comm).to receive(:execute).with(/Set-Acl .*/, shell: "powershell")
        cap.insert_public_key(machine, "ssh-rsa ...")
        expect(File.read(@tempfile.path)).to include("ssh-rsa ...")
      end
    end

    context "when required directories cannot be fetched from the guest" do
      before do
        expect(comm).to receive(:execute).with(/echo .+/, shell: "cmd").and_yield(:stdout, "TEMP\r\n")
      end

      it "should raise an error" do
        expect{ cap.insert_public_key(machine, "ssh-rsa ...") }.to raise_error(VagrantPlugins::GuestWindows::Errors::PublicKeyDirectoryFailure)
      end
    end
  end
end
