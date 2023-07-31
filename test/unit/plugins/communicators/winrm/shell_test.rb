# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/shell")
require Vagrant.source_root.join("plugins/communicators/winrm/config")

describe VagrantPlugins::CommunicatorWinRM::WinRMShell do
  include_context "unit"

  let(:connection) { double("winrm_connection") }
  let(:shell) { double("winrm_shell") }
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
  let(:output) { WinRM::Output.new.tap { |out| out.exitcode = 0 } }

  before { allow(connection).to receive(:shell).and_yield(shell) }

  subject do
    described_class.new('localhost', port, config).tap do |comm|
      allow(comm).to receive(:new_connection).and_return(connection)
    end
  end

  describe "#upload" do
    let(:fm) { double("file_manager") }

    before do
      allow(WinRM::FS::FileManager).to receive(:new).with(connection)
        .and_return(fm)
    end

    it "should call file_manager.upload for each passed in path" do
      from = ["/path", "/path/folder", "/path/folder/file.py"]
      to = "/destination"
      size = 80

      allow(fm).to receive(:upload).and_return(size)

      expect(fm).to receive(:upload).exactly(from.size).times
      expect(subject.upload(from, to)).to eq(size*from.size)
    end

    it "should call file_manager.upload once for a single path" do
      from = "/path/folder/file.py"
      to = "/destination"
      size = 80

      allow(fm).to receive(:upload).and_return(size)

      expect(fm).to receive(:upload).exactly(1).times
      expect(subject.upload(from, to)).to eq(size)
    end

    context "when source is a directory" do
      let(:source) { "path/sourcedir" }

      before do
        allow(File).to receive(:directory?).with(/#{Regexp.escape(source)}/).and_return(true)
      end

      it "should add source directory name to destination" do
        expect(fm).to receive(:upload) do |from, to|
          expect(to).to include("sourcedir")
        end
        subject.upload(source, "/dest")
      end

      it "should not add source directory name to destination when source ends with '.'" do
        source << "/."
        expect(fm).to receive(:upload) do |from, to|
          expect(to).to eq("/dest")
        end
        subject.upload(source, "/dest")
      end
    end
  end

  describe ".powershell" do
    it "should call winrm powershell" do
      expect(shell).to receive(:run).with("dir").and_return(output)
      expect(subject.powershell("dir").exitcode).to eq(0)
    end

    it "should raise an execution error when an exception occurs" do
      expect(shell).to receive(:run).with("dir").and_raise(
        StandardError.new("Oh no! a 500 SOAP error!"))
      expect { subject.powershell("dir") }.to raise_error(
        VagrantPlugins::CommunicatorWinRM::Errors::ExecutionError)
    end
  end

  describe ".elevated" do
    let(:eusername) { double("elevatedusername") }
    let(:username) { double("username") }
    let(:failed_output) { WinRM::Output.new.tap { |out|
        out.exitcode = described_class.const_get(:INVALID_USERID_EXITCODE)
        out << {stderr: "(10,8):UserId:"}
        out << {stderr: "At line:72 char:1"}
      } }

    before do
      allow(subject).to receive(:elevated_username).and_return(eusername)
      allow(shell).to receive(:username).and_return(username)
      allow(shell).to receive(:username=)
    end

    it "should call winrm elevated" do
      expect(shell).to receive(:run).with("dir").and_return(output)
      expect(shell).to receive(:interactive_logon=).with(false)
      expect(subject.elevated("dir").exitcode).to eq(0)
    end

    it "should set interactive_logon when interactive is true" do
      expect(shell).to receive(:run).with("dir").and_return(output)
      expect(shell).to receive(:interactive_logon=).with(true)
      expect(subject.elevated("dir", { interactive: true }).exitcode).to eq(0)
    end

    it "should raise an execution error when an exception occurs" do
      expect(shell).to receive(:run).with("dir").and_raise(
        StandardError.new("Oh no! a 500 SOAP error!"))
      expect { subject.powershell("dir") }.to raise_error(
        VagrantPlugins::CommunicatorWinRM::Errors::ExecutionError)
    end

    it "should use elevated username and retry on username failure" do
      expect(subject).to receive(:elevated_username).and_return(eusername)
      expect(shell).to receive(:run).with("dir").and_return(failed_output)
      expect(shell).to receive(:run).with("dir").and_return(output)
      expect(shell).to receive(:interactive_logon=).with(false)
      expect(subject.elevated("dir").exitcode).to eq(0)
    end

    it "should not retry on username failure if elevated username is the same" do
      expect(subject).to receive(:elevated_username).and_return(username)
      expect(shell).to receive(:run).with("dir").and_return(failed_output)
      expect(shell).to receive(:interactive_logon=).with(false)
      expect(subject.elevated("dir").exitcode).to eq(failed_output.exitcode)
    end
  end

  describe ".cmd" do
    it "should call winrm cmd" do
      expect(connection).to receive(:shell).with(:cmd, { })
      expect(shell).to receive(:run).with("dir").and_return(output)
      expect(subject.cmd("dir").exitcode).to eq(0)
    end

    context "when codepage is given" do
      let(:config)  {
        VagrantPlugins::CommunicatorWinRM::Config.new.tap do |c|
          c.codepage = 800
          c.finalize!
        end
      }

      it "creates shell with the given codepage when set" do
        expect(connection).to receive(:shell).with(:cmd, { codepage: 800 })
        expect(shell).to receive(:run).with("dir").and_return(output)
        expect(subject.cmd("dir").exitcode).to eq(0)
      end
    end
  end

  describe ".wql" do
    it "should call winrm wql" do
      expect(connection).to receive(:run_wql).with("select * from Win32_OperatingSystem")
      subject.wql("select * from Win32_OperatingSystem")
    end

    it "should retry when a WinRMAuthorizationError is received" do
      expect(connection).to receive(:run_wql).with("select * from Win32_OperatingSystem").exactly(2).times.and_raise(
        # Note: The initialize for WinRMAuthorizationError may require a status_code as
        # the second argument in a future WinRM release. Currently it doesn't track the
        # status code.
        WinRM::WinRMAuthorizationError.new("Oh no!! Unauthorized")
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
        { endpoint: "http://localhost:5985/wsman", operation_timeout: 1800,
          user: "username", password: "password", host: "localhost", port: 5985,
          basic_auth_only: false, no_ssl_peer_verification: false,
          retry_delay: 1, retry_limit: 2, transport: :negotiate })
    end
  end

  describe "#elevated_username" do
    let(:username) { "username" }

    before do
      allow(subject).to receive(:username).and_return(username)
      allow(subject).to receive(:powershell)
    end

    it "should return username" do
      expect(subject.send(:elevated_username)).to eq(username)
    end

    it "should attempt to get computer name" do
      expect(subject).to receive(:powershell).with(/computername/)
      subject.send(:elevated_username)
    end

    it "should prepend computer name when available" do
      expect(subject).to receive(:powershell).with(/computername/).and_yield(:stdout, "COMPUTERNAME")
      expect(subject.send(:elevated_username)).to eq("COMPUTERNAME\\#{username}")
    end

    it "should compute elevated username every time" do
      expect(subject).to receive(:powershell).twice.with(/computername/).and_yield(:stdout, "COMPUTERNAME")
      expect(subject.send(:elevated_username)).to eq("COMPUTERNAME\\#{username}")
      expect(subject.send(:elevated_username)).to eq("COMPUTERNAME\\#{username}")
    end

    context "when username includes computer/domain name" do
      let(:username) { "machine\\username" }

      it "should not attempt to get computer name" do
        expect(subject).not_to receive(:powershell)
        expect(subject.send(:elevated_username)).to eq(username)
      end
    end
  end
end
