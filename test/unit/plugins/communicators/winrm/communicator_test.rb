require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/communicator")

describe VagrantPlugins::CommunicatorWinRM::Communicator do
  include_context "unit"

  let(:winrm) { double("winrm", timeout: 1, host: nil, port: 5986, guest_port: 5986) }
  let(:config) { double("config", winrm: winrm) }
  let(:provider) { double("provider") }
  let(:ui) { double("ui") }
  let(:machine) { double("machine", config: config, provider: provider, ui: ui) }
  let(:shell) { double("shell") }
  let(:good_output) { WinRM::Output.new.tap { |out| out.exitcode = 0 } }
  let(:bad_output) { WinRM::Output.new.tap { |out| out.exitcode = 1 } }
  
  subject do
    described_class.new(machine).tap do |comm|
      allow(comm).to receive(:create_shell).and_return(shell)
    end
  end

  before do
    allow(shell).to receive(:username).and_return('vagrant')
    allow(shell).to receive(:password).and_return('password')
    allow(shell).to receive(:execution_time_limit).and_return('PT2H')
  end

  describe ".wait_for_ready" do
    context "with no winrm_info capability and no static config (default scenario)" do
      before do
        # No default providers support this capability
        allow(provider).to receive(:capability?).with(:winrm_info).and_return(false)

        # Get us through the detail prints
        allow(ui).to receive(:detail)
        allow(shell).to receive(:host)
        allow(shell).to receive(:port)
        allow(shell).to receive(:username)
        allow(shell).to receive(:config) { double("config", transport: nil)}
      end

      context "when ssh_info requires a multiple tries before it is ready" do
        before do
          allow(machine).to receive(:ssh_info).and_return(nil, {
            host: '10.1.2.3',
            port: '22',
          })
          # Makes ready? return true
          allow(shell).to receive(:cmd).with("hostname").and_return({ exitcode: 0 })
        end

        it "retries ssh_info until ready" do
          expect(subject.wait_for_ready(2)).to eq(true)
        end
      end
    end
  end

  describe ".ready?" do
    it "returns true if hostname command executes without error" do
      expect(shell).to receive(:cmd).with("hostname").and_return({ exitcode: 0 })
      expect(subject.ready?).to be(true)
    end

    it "returns false if hostname command fails with a transient error" do
      expect(shell).to receive(:cmd).with("hostname").and_raise(VagrantPlugins::CommunicatorWinRM::Errors::TransientError)
      expect(subject.ready?).to be(false)
    end

    it "raises an error if hostname command fails with an unknown error" do
      expect(shell).to receive(:cmd).with("hostname").and_raise(Vagrant::Errors::VagrantError)
      expect { subject.ready? }.to raise_error(Vagrant::Errors::VagrantError)
    end

    it "raises timeout error when hostname command takes longer then winrm timeout" do
      expect(shell).to receive(:cmd).with("hostname") do
        sleep 2 # winrm.timeout = 1
      end
      expect { subject.ready? }.to raise_error(Timeout::Error)
    end
  end

  describe ".execute" do
    it "defaults to running in powershell" do
      expect(shell).to receive(:powershell).with(kind_of(String), kind_of(Hash)).and_return(good_output)
      expect(subject.execute("dir")).to eq(0)
    end

    it "use elevated shell script when elevated is true" do
      expect(shell).to receive(:elevated).and_return(good_output)
      expect(subject.execute("dir", { elevated: true })).to eq(0)
    end

    it "can use cmd shell" do
      expect(shell).to receive(:cmd).with(kind_of(String), kind_of(Hash)).and_return(good_output)
      expect(subject.execute("dir", { shell: :cmd })).to eq(0)
    end

    it "raises error when error_check is true and exit code is non-zero" do
      expect(shell).to receive(:powershell).with(kind_of(String), kind_of(Hash)).and_return(bad_output)
      expect { subject.execute("dir") }.to raise_error(
        VagrantPlugins::CommunicatorWinRM::Errors::WinRMBadExitStatus)
    end

    it "does not raise error when error_check is false and exit code is non-zero" do
      expect(shell).to receive(:powershell).with(kind_of(String), kind_of(Hash)).and_return(bad_output)
      expect(subject.execute("dir", { error_check: false })).to eq(1)
    end
  end

  describe ".test" do
    it "returns true when exit code is zero" do
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return(good_output)
      expect(subject.test("test -d c:/windows")).to be(true)
    end

    it "returns false when exit code is non-zero" do
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return(bad_output)
      expect(subject.test("test -d /tmp/foobar")).to be(false)
    end

    it "returns false when stderr contains output" do
      output = WinRM::Output.new
      output.exitcode = 1
      output << { stderr: 'this is an error' }
      expect(shell).to receive(:powershell).with(kind_of(String)).and_return(output)
      expect(subject.test("[-x stuff] && foo")).to be(false)
    end

    it "returns false when command is testing for linux OS" do
      expect(subject.test("uname -s | grep Debian")).to be(false)
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
