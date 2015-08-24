require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/communicator")

describe VagrantPlugins::CommunicatorWinRM::Communicator do
  include_context "unit"

  let(:winrm) { double("winrm", timeout: 1) }
  let(:config) { double("config", winrm: winrm) }
  let(:machine) { double("machine", config: config) }

  let(:shell) { double("shell") }

  subject do
    described_class.new(machine).tap do |comm|
      allow(comm).to receive(:create_shell).and_return(shell)
    end
  end

  before do
    allow(shell).to receive(:username).and_return('vagrant')
    allow(shell).to receive(:password).and_return('password')
  end

  describe ".ready?" do
    it "returns true if hostname command executes without error" do
      expect(shell).to receive(:powershell).with("hostname").and_return({ exitcode: 0 })
      expect(subject.ready?).to be_true
    end

    it "returns false if hostname command fails with a transient error" do
      expect(shell).to receive(:powershell).with("hostname").and_raise(VagrantPlugins::CommunicatorWinRM::Errors::TransientError)
      expect(subject.ready?).to be_false
    end

    it "raises an error if hostname command fails with an unknown error" do
      expect(shell).to receive(:powershell).with("hostname").and_raise(Vagrant::Errors::VagrantError)
      expect { subject.ready? }.to raise_error(Vagrant::Errors::VagrantError)
    end

    it "raises timeout error when hostname command takes longer then winrm timeout" do
      expect(shell).to receive(:powershell).with("hostname") do
        sleep 2 # winrm.timeout = 1
      end
      expect { subject.ready? }.to raise_error(Timeout::Error)
    end
  end

  describe ".execute" do
    it "defaults to running in powershell" do
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return({ exitcode: 0 })
      expect(subject.execute("dir")).to eq(0)
    end

    it "wraps command in elevated shell script when elevated is true" do
      expect(shell).to receive(:upload).with(kind_of(String), "c:/tmp/vagrant-elevated-shell.ps1")
      expect(shell).to receive(:powershell) do |cmd|
        expect(cmd).to eq("powershell -executionpolicy bypass -file \"c:/tmp/vagrant-elevated-shell.ps1\" " +
          "-username \"vagrant\" -password \"password\" -encoded_command \"ZABpAHIAOwAgAGUAeABpAHQAIAAkAEwAQQBTAFQARQBYAEkAVABDAE8ARABFAA==\"")
      end.and_return({ exitcode: 0 })
      expect(subject.execute("dir", { elevated: true })).to eq(0)
    end

    it "can use cmd shell" do
      expect(shell).to receive(:cmd).with(kind_of(String)).and_return({ exitcode: 0 })
      expect(subject.execute("dir", { shell: :cmd })).to eq(0)
    end

    it "raises error when error_check is true and exit code is non-zero" do
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return(
        { exitcode: 1, data: [{ stdout: '', stderr: '' }] })
      expect { subject.execute("dir") }.to raise_error(
        VagrantPlugins::CommunicatorWinRM::Errors::WinRMBadExitStatus)
    end

    it "does not raise error when error_check is false and exit code is non-zero" do
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return({ exitcode: 1 })
      expect(subject.execute("dir", { error_check: false })).to eq(1)
    end
  end

  describe ".test" do
    it "returns true when exit code is zero" do
      output = { exitcode: 0, data:[{ stderr: '' }] }
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return(output)
      expect(subject.test("test -d c:/windows")).to be_true
    end

    it "returns false when exit code is non-zero" do
      output = { exitcode: 1, data:[{ stderr: '' }] }
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return(output)
      expect(subject.test("test -d /tmp/foobar")).to be_false
    end

    it "returns false when stderr contains output" do
      output = { exitcode: 0, data:[{ stderr: 'this is an error' }] }
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return(output)
      expect(subject.test("[-x stuff] && foo")).to be_false
    end

    it "returns false when command is testing for linux OS" do
      expect(subject.test("uname -s | grep Debian")).to be_false
    end
  end

  describe ".upload" do
    it "calls upload on shell" do
      expect(shell).to receive(:upload).with("from", "to")
      subject.upload("from", "to")
    end
  end

  describe ".download" do
    it "calls download on shell" do
      expect(shell).to receive(:download).with("from", "to")
      subject.download("from", "to")
    end
  end

end
