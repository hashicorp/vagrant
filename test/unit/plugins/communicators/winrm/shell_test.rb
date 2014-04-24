require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/shell")

describe VagrantPlugins::CommunicatorWinRM::WinRMShell do
  include_context "unit"

  let(:session) { double("winrm_session") }

  subject do
    described_class.new('localhost', 'username', 'password').tap do |comm|
      allow(comm).to receive(:new_session).and_return(session)
    end
  end

  describe ".powershell" do
    it "should call winrm powershell" do
      expect(session).to receive(:powershell).with(/^dir.+/).and_return({ exitcode: 0 })
      expect(subject.powershell("dir")[:exitcode]).to eq(0)
    end

    it "should raise auth error when exception message contains 401" do
      expect(session).to receive(:powershell).with(/^dir.+/).and_raise(
        StandardError.new("Oh no! a 401 SOAP error!"))
      expect { subject.powershell("dir") }.to raise_error(
        VagrantPlugins::CommunicatorWinRM::Errors::AuthError)
    end

    it "should raise an execution error when an exception occurs" do
      expect(session).to receive(:powershell).with(/^dir.+/).and_raise(
        StandardError.new("Oh no! a 500 SOAP error!"))
      expect { subject.powershell("dir") }.to raise_error(
        VagrantPlugins::CommunicatorWinRM::Errors::ExecutionError)
    end
  end

  describe ".cmd" do
    it "should call winrm cmd" do
      expect(session).to receive(:cmd).with("dir").and_return({ exitcode: 0 })
      expect(subject.cmd("dir")[:exitcode]).to eq(0)
    end
  end

  describe ".endpoint" do
    it "should create winrm endpoint address" do
      expect(subject.send(:endpoint)).to eq("http://localhost:5985/wsman")
    end
  end

  describe ".endpoint_options" do
    it "should create endpoint options" do
      expect(subject.send(:endpoint_options)).to eq(
        { user: "username", pass: "password", host: "localhost", port: 5985,
          operation_timeout: 60, basic_auth_only: true })
    end
  end

end
