require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/ssh/communicator")

describe VagrantPlugins::CommunicatorSSH::Communicator do
  include_context "unit"

  let(:export_command_template){ 'export %ENV_KEY%="%ENV_VALUE%"' }

  # SSH configuration information mock
  let(:ssh) do
    double("ssh",
      timeout: 1,
      host: nil,
      port: 5986,
      guest_port: 5986,
      pty: false,
      keep_alive: false,
      insert_key: insert_ssh_key,
      export_command_template: export_command_template,
      shell: 'bash -l'
    )
  end
  # Do not insert public key by default
  let(:insert_ssh_key){ false }
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
      ui: ui,
      env: env
    )
  end
  let(:env){ double("env", host: host) }
  let(:host){ double("host") }
  # SSH information of the machine
  let(:machine_ssh_info){ {host: '10.1.2.3', port: 22} }
  # Subject instance to test
  let(:communicator){ @communicator ||= described_class.new(machine) }
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
  let(:command_garbage_marker) { communicator.class.const_get(:CMD_GARBAGE_MARKER) }
  # Start marker output when PTY is enabled
  let(:pty_delim_start) { communicator.class.const_get(:PTY_DELIM_START) }
  # End marker output when PTY is enabled
  let(:pty_delim_end) { communicator.class.const_get(:PTY_DELIM_END) }
  # Command output returned on stdout
  let(:command_stdout_data) { '' }
  # Command output returned on stderr
  let(:command_stderr_data) { '' }
  # Mock for net-ssh scp
  let(:scp) { double("scp") }


  # Setup for commands using the net-ssh connection. This can be reused where needed
  # by providing to `before`
  connection_setup = proc do
    allow(connection).to receive(:closed?).and_return false
    allow(connection).to receive(:open_channel).
      and_yield(channel).and_return(channel)
    allow(connection).to receive(:close)
    allow(channel).to receive(:wait).and_return true
    allow(channel).to receive(:close)
    allow(command_channel).to receive(:send_data)
    allow(command_channel).to receive(:eof!)
    allow(command_channel).to receive(:on_data).
      and_yield(nil, command_stdout_data)
    allow(command_channel).to receive(:on_extended_data).
      and_yield(nil, nil, command_stderr_data)
    allow(machine).to receive(:ssh_info).and_return(machine_ssh_info)
    allow(channel).to receive(:exec).with(core_shell_cmd).
      and_yield(command_channel, '').and_return channel
    allow(command_channel).to receive(:on_request).with('exit-status').
      and_yield(nil, exit_data)
    # Return mocked net-ssh connection during setup
    allow(communicator).to receive(:retryable).and_return(connection)
  end

  before do
    allow(host).to receive(:capability?).and_return(false)
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
          expect(communicator.wait_for_ready(0.6)).to eq(true)
        end
      end

      context "when printing message to the user" do
        before do
          allow(machine).to receive(:ssh_info).
            and_return(host: '10.1.2.3', port: 22).ordered
          allow(communicator).to receive(:connect)
          allow(communicator).to receive(:ready?).and_return(true)
        end

        it "should print message" do
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHConnectionTimeout)
          expect(ui).to receive(:detail).with(/timeout/)
          communicator.wait_for_ready(0.5)
        end

        it "should not print the same message twice" do
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHConnectionTimeout)
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHConnectionTimeout)
          expect(ui).to receive(:detail).with(/timeout/)
          expect(ui).not_to receive(:detail).with(/timeout/)
          communicator.wait_for_ready(0.5)
        end

        it "should print different messages" do
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHConnectionTimeout)
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHDisconnected)
          expect(ui).to receive(:detail).with(/timeout/)
          expect(ui).to receive(:detail).with(/disconnect/)
          communicator.wait_for_ready(0.5)
        end

        it "should not print different messages twice" do
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHConnectionTimeout)
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHDisconnected)
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHConnectionTimeout)
          expect(communicator).to receive(:connect).and_raise(Vagrant::Errors::SSHDisconnected)
          expect(ui).to receive(:detail).with(/timeout/)
          expect(ui).to receive(:detail).with(/disconnect/)
          expect(ui).not_to receive(:detail).with(/timeout/)
          expect(ui).not_to receive(:detail).with(/disconnect/)
          communicator.wait_for_ready(0.5)
        end
      end
    end
  end

  describe "reset!" do
    let(:connection) { double("connection") }

    before do
      allow(communicator).to receive(:wait_for_ready)
      allow(connection).to receive(:close)
      communicator.send(:instance_variable_set, :@connection, connection)
    end

    it "should close existing connection" do
      expect(connection).to receive(:close)
      communicator.reset!
    end

    it "should call wait_for_ready to re-enable the connection" do
      expect(communicator).to receive(:wait_for_ready)
      communicator.reset!
    end
  end

  describe ".ready?" do
    before(&connection_setup)
    it "returns true if shell test is successful" do
      expect(communicator.ready?).to be(true)
    end

    context "with an invalid shell test" do
      before do
        expect(exit_data).to receive(:read_long).and_return 1
      end

      it "returns raises SSHInvalidShell error" do
        expect{ communicator.ready? }.to raise_error Vagrant::Errors::SSHInvalidShell
      end
    end

    context "with insert key enabled" do
      before do
        allow(machine).to receive(:guest).and_return(guest)
        allow(guest).to receive(:capability?).with(:insert_public_key).
          and_return(has_insert_cap)
        allow(guest).to receive(:capability?).with(:remove_public_key).
          and_return(has_remove_cap)
        allow(communicator).to receive(:insecure_key?).with("KEY_PATH").and_return(true)
        allow(ui).to receive(:detail)
      end

      let(:insert_ssh_key){ true }
      let(:has_insert_cap){ false }
      let(:has_remove_cap){ false }
      let(:machine_ssh_info){
        {host: '10.1.2.3', port: 22, private_key_path: ["KEY_PATH"]}
      }
      let(:guest){ double("guest") }

      context "without guest insert_ssh_key or remove_ssh_key capabilities" do
        it "should raise an error" do
          expect{ communicator.ready? }.to raise_error(Vagrant::Errors::SSHInsertKeyUnsupported)
        end
      end

      context "without guest insert_ssh_key capability" do
        let(:has_remove_cap){ true }

        it "should raise an error" do
          expect{ communicator.ready? }.to raise_error(Vagrant::Errors::SSHInsertKeyUnsupported)
        end
      end

      context "without guest remove_ssh_key capability" do
        let(:has_insert_cap){ true }

        it "should raise an error" do
          expect{ communicator.ready? }.to raise_error(Vagrant::Errors::SSHInsertKeyUnsupported)
        end
      end

      context "with guest insert_ssh_key capability and remove_ssh_key capability" do
        let(:has_insert_cap){ true }
        let(:has_remove_cap){ true }
        let(:new_public_key){ :new_public_key }
        let(:new_private_key){ :new_private_key }
        let(:openssh){ :openssh }
        let(:private_key_file){ double("private_key_file") }
        let(:path_joiner){ double("path_joiner") }

        before do
          allow(ui).to receive(:info)
          allow(Vagrant::Util::Keypair).to receive(:create).
            and_return([new_public_key, new_private_key, openssh])
          allow(private_key_file).to receive(:open).and_yield(private_key_file)
          allow(private_key_file).to receive(:write)
          allow(private_key_file).to receive(:chmod)
          allow(guest).to receive(:capability)
          allow(File).to receive(:chmod)
          allow(machine).to receive(:data_dir).and_return(path_joiner)
          allow(path_joiner).to receive(:join).and_return(private_key_file)
          allow(guest).to receive(:capability).with(:insert_public_key)
          allow(guest).to receive(:capability).with(:remove_public_key)
        end

        after{ communicator.ready? }

        it "should create a new key pair" do
          expect(Vagrant::Util::Keypair).to receive(:create).
            and_return([new_public_key, new_private_key, openssh])
        end

        it "should call the insert_public_key guest capability" do
          expect(guest).to receive(:capability).with(:insert_public_key, openssh)
        end

        it "should write the new private key" do
          expect(private_key_file).to receive(:write).with(new_private_key)
        end

        it "should call the set_ssh_key_permissions host capability" do
          expect(host).to receive(:capability?).with(:set_ssh_key_permissions).and_return(true)
          expect(host).to receive(:capability).with(:set_ssh_key_permissions, private_key_file)
        end

        it "should remove the default public key" do
          expect(guest).to receive(:capability).with(:remove_public_key, any_args)
        end
      end
    end
  end

  describe ".execute" do
    before(&connection_setup)
    it "runs valid command and returns successful status code" do
      expect(command_channel).to receive(:send_data).with(/ls \/\n/)
      expect(communicator.execute("ls /")).to eq(0)
    end

    it "prepends UUID output to command for garbage removal" do
      expect(command_channel).to receive(:send_data).
        with("printf '#{command_garbage_marker}'\n(>&2 printf '#{command_garbage_marker}')\nls /\n")
      expect(communicator.execute("ls /")).to eq(0)
    end

    context "with command returning an error" do
      let(:exit_data) { double("exit_data", read_long: 1) }

      it "raises error when exit-code is non-zero" do
        expect(command_channel).to receive(:send_data).with(/ls \/\n/)
        expect{ communicator.execute("ls /") }.to raise_error(Vagrant::Errors::VagrantError)
      end

      it "returns exit-code when exit-code is non-zero and error check is disabled" do
        expect(command_channel).to receive(:send_data).with(/ls \/\n/)
        expect(communicator.execute("ls /", error_check: false)).to eq(1)
      end
    end

    context "with garbage content prepended to command output" do
      let(:command_stdout_data) do
        "Line of garbage\nMore garbage\n#{command_garbage_marker}bin\ntmp\n"
      end
      let(:command_stderr_data) { "some data" }

      it "removes any garbage output prepended to command output" do
        stdout = ''
        expect(
          communicator.execute("ls /") do |type, data|
            if type == :stdout
              stdout << data
            end
          end
        ).to eq(0)
        expect(stdout).to eq("bin\ntmp\n")
      end

      it "should not receive any stderr data" do
        stderr = ''
        communicator.execute("ls /") do |type, data|
          if type == :stderr
            stderr << data
          end
        end
        expect(stderr).to be_empty
      end
    end

    context "with no command output" do
      let(:command_stdout_data) do
        "#{command_garbage_marker}"
      end
      let(:command_stderr_data) { "some data" }

      it "does not send empty stdout data string" do
        empty = true
        expect(
          communicator.execute("ls /") do |type, data|
            if type == :stdout && data.empty?
              empty = false
            end
          end
        ).to eq(0)
        expect(empty).to be(true)
      end

      it "should not receive any stderr data" do
        stderr = ''
        communicator.execute("ls /") do |type, data|
          if type == :stderr
            stderr << data
          end
        end
        expect(stderr).to be_empty
      end
    end

    context "with garbage content prepended to command stderr output" do
      let(:command_stderr_data) do
        "Line of garbage\nMore garbage\n#{command_garbage_marker}bin\ntmp\n"
      end
      let(:command_stdout_data) { "some data" }

      it "removes any garbage output prepended to command stderr output" do
        stderr = ''
        expect(
          communicator.execute("ls /") do |type, data|
            if type == :stderr
              stderr << data
            end
          end
        ).to eq(0)
        expect(stderr).to eq("bin\ntmp\n")
      end

      it "should not receive any stdout data" do
        stdout = ''
        communicator.execute("ls /") do |type, data|
          if type == :stdout
            stdout << data
          end
        end
        expect(stdout).to be_empty
      end
    end

    context "with no command output on stderr" do
      let(:command_stderr_data) do
        "#{command_garbage_marker}"
      end
      let(:command_std_data) { "some data" }

      it "does not send empty stderr data string" do
        empty = true
        expect(
          communicator.execute("ls /") do |type, data|
            if type == :stderr && data.empty?
              empty = false
            end
          end
        ).to eq(0)
        expect(empty).to be(true)
      end

      it "should not receive any stdout data" do
        stdout = ''
        communicator.execute("ls /") do |type, data|
          if type == :stdout
            stdout << data
          end
        end
        expect(stdout).to be_empty
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
        expect(communicator.execute("ls")).to eq(0)
      end

      context "with sudo enabled" do
        let(:core_shell_cmd){ 'sudo bash -l' }

        before do
          expect(ssh).to receive(:sudo_command).and_return 'sudo %c'
        end

        it "wraps command in elevated shell when sudo is true" do
          expect(communicator.execute("ls", sudo: true)).to eq(0)
        end
      end
    end

    context "with sudo enabled" do
      let(:core_shell_cmd){ 'sudo bash -l' }

      before do
        expect(ssh).to receive(:sudo_command).and_return 'sudo %c'
      end

      it "wraps command in elevated shell when sudo is true" do
        expect(communicator.execute("ls", sudo: true)).to eq(0)
      end
    end
  end

  describe ".test" do
    before(&connection_setup)
    context "with exit code as zero" do
      it "returns true" do
        expect(communicator.test("ls")).to be(true)
      end
    end

    context "with exit code as non-zero" do
      before do
        expect(exit_data).to receive(:read_long).and_return 1
      end

      it "returns false" do
        expect(communicator.test("/bin/false")).to be(false)
      end
    end
  end

  describe ".upload" do
    before do
      expect(communicator).to receive(:scp_connect).and_yield(scp)
      allow(communicator).to receive(:create_remote_directory)
    end

    context "directory uploads" do
      let(:test_dir) { @dir }
      let(:test_file) { File.join(test_dir, "test-file") }
      let(:dir_name) { File.basename(test_dir) }
      let(:file_name) { File.basename(test_file) }

      before do
        @dir = Dir.mktmpdir("vagrant-test")
        FileUtils.touch(test_file)
      end

      after { FileUtils.rm_rf(test_dir) }

      it "uploads directory when directory path provided" do
        expect(scp).to receive(:upload!).with(instance_of(File),
          File.join("", "destination", dir_name, file_name))
        communicator.upload(test_dir, "/destination")
      end

      it "uploads contents of directory when dot suffix provided on directory" do
        expect(scp).to receive(:upload!).with(instance_of(File),
          File.join("", "destination", file_name))
        communicator.upload(File.join(test_dir, "."), "/destination")
      end

      it "creates directories before upload" do
        expect(communicator).to receive(:create_remote_directory).with(
          /#{Regexp.escape(File.join("", "destination", dir_name))}/)
        allow(scp).to receive(:upload!)
        communicator.upload(test_dir, "/destination")
      end
    end

    it "uploads a file if local path is a file" do
      file = Tempfile.new('vagrant-test')
      begin
        expect(scp).to receive(:upload!).with(instance_of(File), '/destination/file')
        communicator.upload(file.path, '/destination/file')
      ensure
        file.delete
      end
    end

    it "uploads file to directory if destination ends with file separator" do
      file = Tempfile.new('vagrant-test')
      begin
        expect(scp).to receive(:upload!).with(instance_of(File), "/destination/dir/#{File.basename(file.path)}")
        expect(communicator).to receive(:create_remote_directory).with("/destination/dir")
        communicator.upload(file.path, "/destination/dir/")
      ensure
        file.delete
      end
    end

    it "creates remote directory path to destination on upload" do
      file = Tempfile.new('vagrant-test')
      begin
        expect(scp).to receive(:upload!).with(instance_of(File), "/destination/dir/file.txt")
        expect(communicator).to receive(:create_remote_directory).with("/destination/dir")
        communicator.upload(file.path, "/destination/dir/file.txt")
      ensure
        file.delete
      end
    end

    it "raises custom error on permission errors" do
      file = Tempfile.new('vagrant-test')
      begin
        expect(scp).to receive(:upload!).with(instance_of(File), '/destination/file').
          and_raise("Permission denied")
        expect{ communicator.upload(file.path, '/destination/file') }.to(
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
        expect{ communicator.upload(file.path, '/destination/file') }.to raise_error(RuntimeError)
      ensure
        file.delete
      end
    end
  end

  describe ".download" do
    before do
      expect(communicator).to receive(:scp_connect).and_yield(scp)
    end

    it "calls scp to download file" do
      expect(scp).to receive(:download!).with('/path/from', '/path/to')
      communicator.download('/path/from', '/path/to')
    end
  end

  describe ".connect" do

    it "cannot be called directly" do
      expect{ communicator.connect }.to raise_error(NoMethodError)
    end

    context "with default configuration" do

      before do
        expect(machine).to receive(:ssh_info).and_return(
          host: nil,
          port: nil,
          private_key_path: nil,
          username: nil,
          password: nil,
          keys_only: true,
          verify_host_key: false
        )
      end

      it "has keys_only enabled" do
        expect(Net::SSH).to receive(:start).with(
          nil, nil, hash_including(
            keys_only: true
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "has verify_host_key disabled" do
        expect(Net::SSH).to receive(:start).with(
          nil, nil, hash_including(
            verify_host_key: false
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "does not include any private key paths" do
        expect(Net::SSH).to receive(:start).with(
          nil, nil, hash_excluding(
            keys: anything
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "includes `none` and `hostbased` auth methods" do
        expect(Net::SSH).to receive(:start).with(
          nil, nil, hash_including(
            auth_methods: ["none", "hostbased"]
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "includes the default cipher array for encryption" do
        cipher_array = %w(aes256-ctr aes192-ctr aes128-ctr
                          aes256-cbc aes192-cbc aes128-cbc
                          rijndael-cbc@lysator.liu.se blowfish-ctr
                          blowfish-cbc cast128-ctr cast128-cbc
                          3des-ctr 3des-cbc idea-cbc arcfour256
                          arcfour128 arcfour none)

        expect(Net::SSH).to receive(:start).with(
          nil, nil, hash_including(
            encryption: cipher_array
          )
        ).and_return(true)
        communicator.send(:connect)
      end
    end

    context "with keys_only disabled and verify_host_key enabled" do

      before do
        expect(machine).to receive(:ssh_info).and_return(
          host: nil,
          port: nil,
          private_key_path: nil,
          username: nil,
          password: nil,
          keys_only: false,
          verify_host_key: true
        )
      end

      it "has keys_only enabled" do
        expect(Net::SSH).to receive(:start).with(
          nil, nil, hash_including(
            keys_only: false
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "has verify_host_key disabled" do
        expect(Net::SSH).to receive(:start).with(
          nil, nil, hash_including(
            verify_host_key: true
          )
        ).and_return(true)
        communicator.send(:connect)
      end
    end

    context "with host and port configured" do

      before do
        expect(machine).to receive(:ssh_info).and_return(
          host: '127.0.0.1',
          port: 2222,
          private_key_path: nil,
          username: nil,
          password: nil,
          keys_only: true,
          verify_host_key: false
        )
      end

      it "specifies configured host" do
        expect(Net::SSH).to receive(:start).with("127.0.0.1", anything, anything)
        communicator.send(:connect)
      end

      it "has port defined" do
        expect(Net::SSH).to receive(:start).with("127.0.0.1", anything, hash_including(port: 2222))
        communicator.send(:connect)
      end
    end

    context "with private_key_path configured" do
      before do
        expect(machine).to receive(:ssh_info).and_return(
          host: '127.0.0.1',
          port: 2222,
          private_key_path: ['/priv/key/path'],
          username: nil,
          password: nil,
          keys_only: true,
          verify_host_key: false
        )
      end

      it "includes private key paths" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            keys: ["/priv/key/path"]
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "includes `publickey` auth method" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            auth_methods: ["none", "hostbased", "publickey"]
          )
        ).and_return(true)
        communicator.send(:connect)
      end
    end

    context "with username and password configured" do

      before do
        expect(machine).to receive(:ssh_info).and_return(
          host: '127.0.0.1',
          port: 2222,
          private_key_path: nil,
          username: 'vagrant',
          password: 'vagrant',
          keys_only: true,
          verify_host_key: false
        )
      end

      it "has username defined" do
        expect(Net::SSH).to receive(:start).with(anything, 'vagrant', anything).and_return(true)
        communicator.send(:connect)
      end

      it "has password defined" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            password: 'vagrant'
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "includes `password` auth method" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            auth_methods: ["none", "hostbased", "password"]
          )
        ).and_return(true)
        communicator.send(:connect)
      end
    end

    context "with password and private_key_path configured" do

      before do
        expect(machine).to receive(:ssh_info).and_return(
          host: '127.0.0.1',
          port: 2222,
          private_key_path: ['/priv/key/path'],
          username: 'vagrant',
          password: 'vagrant',
          keys_only: true,
          verify_host_key: false
        )
      end

      it "has password defined" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            password: 'vagrant'
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "includes private key paths" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            keys: ["/priv/key/path"]
          )
        ).and_return(true)
        communicator.send(:connect)
      end

      it "includes `publickey` and `password` auth methods" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            auth_methods: ["none", "hostbased", "publickey", "password"]
          )
        ).and_return(true)
        communicator.send(:connect)
      end
    end

    context "with config configured" do
      before do
        expect(machine).to receive(:ssh_info).and_return(
          host: '127.0.0.1',
          port: 2222,
          config: './ssh_config',
          keys_only: true,
          verify_host_key: false
        )
      end

      it "has config defined" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            config: './ssh_config'
          )
        ).and_return(true)
        communicator.send(:connect)
      end
    end

    context "with remote_user configured" do
      let(:remote_user) { double("remote_user") }

      before do
        expect(machine).to receive(:ssh_info).and_return(
          host: '127.0.0.1',
          port: 2222,
          remote_user: remote_user
        )
      end

      it "has remote_user defined" do
        expect(Net::SSH).to receive(:start).with(
          anything, anything, hash_including(
            remote_user: remote_user
          )
        ).and_return(true)
        communicator.send(:connect)
      end
    end
  end

  describe ".generate_environment_export" do
    it "should generate bourne shell compatible export" do
      expect(communicator.send(:generate_environment_export, "TEST", "value")).to eq("export TEST=\"value\"\n")
    end

    context "with custom template defined" do
      let(:export_command_template){ "setenv %ENV_KEY% %ENV_VALUE%" }

      it "should generate custom export based on template" do
        expect(communicator.send(:generate_environment_export, "TEST", "value")).to eq("setenv TEST value\n")
      end
    end
  end
end
