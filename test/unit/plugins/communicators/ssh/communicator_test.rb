require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/ssh/communicator")

describe VagrantPlugins::CommunicatorSSH::Communicator do
  include_context "unit"

  # SSH configuration information mock
  let(:ssh) do
    double("ssh",
      timeout: 1,
      host: nil,
      port: 5986,
      guest_port: 5986,
      pty: false,
      keep_alive: false,
      insert_key: false,
      shell: 'bash -l'
    )
  end
  # Configuration mock
  let(:config) { double("config", ssh: ssh) }
  # Provider mock
  let(:provider) { double("provider") }
  # UI mock
  let(:ui) { double("ui") }
  # Machine mock built with previously defined
  let(:machine) do
    double("machine",
      config: config,
      provider: provider,
      ui: ui
    )
  end
  # Underlying net-ssh connection mock
  let(:connection) { double("connection") }
  # Base net-ssh connection channel mock
  let(:channel) { double("channel") }
  # net-ssh connection channel mock for running commands
  let(:command_channel) { double("command_channel") }
  # Default exit data for commands run
  let(:exit_data) { double("exit_data", read_long: 0) }
  # Core shell command used when starting command connection
  let(:core_shell_cmd) { "bash -l" }
  # Marker used for flagging start of output
  let(:command_garbage_marker) { subject.class.const_get(:CMD_GARBAGE_MARKER) }
  # Start marker output when PTY is enabled
  let(:pty_delim_start) { subject.class.const_get(:PTY_DELIM_START) }
  # End marker output when PTY is enabled
  let(:pty_delim_end) { subject.class.const_get(:PTY_DELIM_END) }
  # Command output returned on stdout
  let(:command_stdout_data) { '' }
  # Command output returned on stderr
  let(:command_stderr_data) { '' }
  # Mock for net-ssh scp
  let(:scp) { double("scp") }

  # Return mocked net-ssh connection during setup
  subject do
    described_class.new(machine).tap do |comm|
      allow(comm).to receive(:retryable).and_return(connection)
    end
  end

  # Setup for commands using the net-ssh connection. This can be reused where needed
  # by providing to `before`
  connection_setup = proc do
    allow(connection).to receive(:closed?).and_return false
    allow(connection).to receive(:open_channel).
      and_yield(channel).and_return(channel)
    allow(channel).to receive(:wait).and_return true
    allow(channel).to receive(:close)
    allow(command_channel).to receive(:send_data)
    allow(command_channel).to receive(:eof!)
    allow(command_channel).to receive(:on_data).
      and_yield(nil, command_stdout_data)
    allow(command_channel).to receive(:on_extended_data).
      and_yield(nil, nil, command_stderr_data)
    allow(machine).to receive(:ssh_info).and_return(host: '10.1.2.3', port: 22)
    expect(channel).to receive(:exec).with(core_shell_cmd).
      and_yield(command_channel, '').and_return channel
    expect(command_channel).to receive(:on_request).with('exit-status').
      and_yield(nil, exit_data)
  end

  describe ".wait_for_ready" do
    before(&connection_setup)
    context "with no static config (default scenario)" do
      before do
        allow(ui).to receive(:detail)
      end

      context "when ssh_info requires a multiple tries before it is ready" do
        before do
          expect(machine).to receive(:ssh_info).
            and_return(nil).ordered
          expect(machine).to receive(:ssh_info).
            and_return(host: '10.1.2.3', port: 22).ordered
        end

        it "retries ssh_info until ready" do
          # retries are every 0.5 so buffer the timeout just a hair over
          expect(subject.wait_for_ready(0.6)).to eq(true)
        end
      end
    end
  end

  describe ".ready?" do
    before(&connection_setup)
    it "returns true if shell test is successful" do
      expect(subject.ready?).to be_true
    end

    context "with an invalid shell test" do
      before do
        expect(exit_data).to receive(:read_long).and_return 1
      end

      it "returns raises SSHInvalidShell error" do
        expect{ subject.ready? }.to raise_error Vagrant::Errors::SSHInvalidShell
      end
    end
  end

  describe ".execute" do
    before(&connection_setup)
    it "runs valid command and returns successful status code" do
      expect(command_channel).to receive(:send_data).with(/ls \/\n/)
      expect(subject.execute("ls /")).to eq(0)
    end

    it "prepends UUID output to command for garbage removal" do
      expect(command_channel).to receive(:send_data).
        with("printf '#{command_garbage_marker}'\nls /\n")
      expect(subject.execute("ls /")).to eq(0)
    end

    context "with command returning an error" do
      let(:exit_data) { double("exit_data", read_long: 1) }

      it "raises error when exit-code is non-zero" do
        expect(command_channel).to receive(:send_data).with(/ls \/\n/)
        expect{ subject.execute("ls /") }.to raise_error(Vagrant::Errors::VagrantError)
      end

      it "returns exit-code when exit-code is non-zero and error check is disabled" do
        expect(command_channel).to receive(:send_data).with(/ls \/\n/)
        expect(subject.execute("ls /", error_check: false)).to eq(1)
      end
    end

    context "with garbage content prepended to command output" do
      let(:command_stdout_data) do
        "Line of garbage\nMore garbage\n#{command_garbage_marker}bin\ntmp\n"
      end

      it "removes any garbage output prepended to command output" do
        stdout = ''
        expect(
          subject.execute("ls /") do |type, data|
            stdout << data
          end
        ).to eq(0)
        expect(stdout).to eq("bin\ntmp\n")
      end
    end

    context "with pty enabled" do
      before do
        expect(ssh).to receive(:pty).and_return true
        expect(channel).to receive(:request_pty).and_yield(command_channel, true)
        expect(command_channel).to receive(:send_data).
          with(/#{Regexp.escape(pty_delim_start)}/)
      end

      let(:command_stdout_data) do
        "#{pty_delim_start}bin\ntmp\n#{pty_delim_end}"
      end

      it "requests pty for connection" do
        expect(subject.execute("ls")).to eq(0)
      end

      context "with sudo enabled" do
        let(:core_shell_cmd){ 'sudo bash -l' }

        before do
          expect(ssh).to receive(:sudo_command).and_return 'sudo %c'
        end

        it "wraps command in elevated shell when sudo is true" do
          expect(subject.execute("ls", sudo: true)).to eq(0)
        end
      end
    end

    context "with sudo enabled" do
      let(:core_shell_cmd){ 'sudo bash -l' }

      before do
        expect(ssh).to receive(:sudo_command).and_return 'sudo %c'
      end

      it "wraps command in elevated shell when sudo is true" do
        expect(subject.execute("ls", sudo: true)).to eq(0)
      end
    end
  end

  describe ".test" do
    before(&connection_setup)
    context "with exit code as zero" do
      it "returns true" do
        expect(subject.test("ls")).to be_true
      end
    end

    context "with exit code as non-zero" do
      before do
        expect(exit_data).to receive(:read_long).and_return 1
      end

      it "returns false" do
        expect(subject.test("/bin/false")).to be_false
      end
    end
  end

  describe ".upload" do
    before do
      expect(subject).to receive(:scp_connect).and_yield(scp)
    end

    it "uploads a directory if local path is a directory" do
      Dir.mktmpdir('vagrant-test') do |dir|
        expect(scp).to receive(:upload!).with(dir, '/destination', recursive: true)
        subject.upload(dir, '/destination')
      end
    end

    it "uploads a file if local path is a file" do
      file = Tempfile.new('vagrant-test')
      begin
        expect(scp).to receive(:upload!).with(instance_of(File), '/destination/file')
        subject.upload(file.path, '/destination/file')
      ensure
        file.delete
      end
    end

    it "raises custom error on permission errors" do
      file = Tempfile.new('vagrant-test')
      begin
        expect(scp).to receive(:upload!).with(instance_of(File), '/destination/file').
          and_raise("Permission denied")
        expect{ subject.upload(file.path, '/destination/file') }.to(
          raise_error(Vagrant::Errors::SCPPermissionDenied)
        )
      ensure
        file.delete
      end
    end

    it "does not raise custom error on non-permission errors" do
      file = Tempfile.new('vagrant-test')
      begin
        expect(scp).to receive(:upload!).with(instance_of(File), '/destination/file').
          and_raise("Some other error")
        expect{ subject.upload(file.path, '/destination/file') }.to raise_error(RuntimeError)
      ensure
        file.delete
      end
    end
  end

  describe ".download" do
    before do
      expect(subject).to receive(:scp_connect).and_yield(scp)
    end

    it "calls scp to download file" do
      expect(scp).to receive(:download!).with('/path/from', '/path/to')
      subject.download('/path/from', '/path/to')
    end
  end
end
