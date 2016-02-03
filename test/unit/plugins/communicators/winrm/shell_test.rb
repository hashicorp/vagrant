require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/shell")
require Vagrant.source_root.join("plugins/communicators/winrm/config")

describe VagrantPlugins::CommunicatorWinRM::WinRMShell do
  include_context "unit"

  let(:session) { double("winrm_session", create_executor: executor) }
  let(:executor) { double("command_executor") }
  let(:port) { config.transport == :ssl ? 5986 : 5985 }
  let(:config)  {
    VagrantPlugins::CommunicatorWinRM::Config.new.tap do |c|
      c.username = 'username'
      c.password = 'password'
      c.max_tries = 3
      c.retry_delay = 0
      c.basic_auth_only = false
      c.retry_delay = 1
      c.max_tries = 2
      c.finalize!
    end
  }

  subject do
    described_class.new('localhost', port, config).tap do |comm|
      allow(comm).to receive(:new_session).and_return(session)
    end
  end

  describe ".powershell" do
    it "should call winrm powershell" do
      expect(executor).to receive(:run_powershell_script).with(/^dir.+/).and_return({ exitcode: 0 })
      expect(subject.powershell("dir")[:exitcode]).to eq(0)
    end

    it "should raise an execution error when an exception occurs" do
      expect(executor).to receive(:run_powershell_script).with(/^dir.+/).and_raise(
        StandardError.new("Oh no! a 500 SOAP error!"))
      expect { subject.powershell("dir") }.to raise_error(
        VagrantPlugins::CommunicatorWinRM::Errors::ExecutionError)
    end
  end

  describe ".cmd" do
    it "should call winrm cmd" do
      expect(executor).to receive(:run_cmd).with("dir").and_return({ exitcode: 0 })
      expect(subject.cmd("dir")[:exitcode]).to eq(0)
    end
  end

  describe ".wql" do
    it "should call winrm wql" do
      expect(session).to receive(:run_wql).with("select * from Win32_OperatingSystem").and_return({ exitcode: 0 })
      expect(subject.wql("select * from Win32_OperatingSystem")[:exitcode]).to eq(0)
    end

    it "should retry when a WinRMAuthorizationError is received" do
      expect(session).to receive(:run_wql).with("select * from Win32_OperatingSystem").exactly(2).times.and_raise(
        # Note: The initialize for WinRMAuthorizationError may require a status_code as
        # the second argument in a future WinRM release. Currently it doesn't track the
        # status code.
        WinRM::WinRMAuthorizationError.new("Oh no!! Unauthrorized")
      )
      expect { subject.wql("select * from Win32_OperatingSystem") }.to raise_error(
        VagrantPlugins::CommunicatorWinRM::Errors::AuthenticationFailed)
    end
  end

  describe ".endpoint" do
    context 'when transport is :ssl' do
      let(:config)  {
        VagrantPlugins::CommunicatorWinRM::Config.new.tap do |c|
          c.transport = :ssl
          c.finalize!
        end
      }
      it "should create winrm endpoint address using https" do
        expect(subject.send(:endpoint)).to eq("https://localhost:5986/wsman")
      end
    end

    context "when transport is :negotiate" do
      it "should create winrm endpoint address using http" do
        expect(subject.send(:endpoint)).to eq("http://localhost:5985/wsman")
      end
    end

    context "when transport is :plaintext" do
      let(:config)  {
        VagrantPlugins::CommunicatorWinRM::Config.new.tap do |c|
          c.transport = :plaintext
          c.finalize!
        end
      }
      it "should create winrm endpoint address using http" do
        expect(subject.send(:endpoint)).to eq("http://localhost:5985/wsman")
      end
    end
  end

  describe ".endpoint_options" do
    it "should create endpoint options" do
      expect(subject.send(:endpoint_options)).to eq(
        { user: "username", pass: "password", host: "localhost", port: 5985,
          basic_auth_only: false, no_ssl_peer_verification: false,
          retry_delay: 1, retry_limit: 2 })
    end
  end

end
