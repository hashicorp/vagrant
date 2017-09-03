require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/ssh_config/command")

describe VagrantPlugins::CommandSSHConfig::Command do
  include_context "unit"
  include_context "virtualbox"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest)   { double("guest") }
  let(:host)    { double("host") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  let(:argv)     { [] }
  let(:ssh_info) {{
    host:             "testhost.vagrant.dev",
    port:             1234,
    username:         "testuser",
    keys_only:        true,
    paranoid:         false,
    private_key_path: ["/home/vagrant/.private/keys.key"],
    forward_agent:    false,
    forward_x11:      false
  }}

  subject { described_class.new(argv, iso_env) }

  before do
    allow(machine).to receive(:ssh_info).and_return(ssh_info)
    allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
  end

  describe "execute" do
    it "prints out the ssh config for the given machine" do
      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute

      expect(output).to eq(<<-SSHCONFIG)
Host #{machine.name}
  HostName testhost.vagrant.dev
  User testuser
  Port 1234
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentityFile /home/vagrant/.private/keys.key
  IdentitiesOnly yes
  LogLevel FATAL
      SSHCONFIG
    end

    it "turns on agent forwarding when it is configured" do
      allow(machine).to receive(:ssh_info) { ssh_info.merge(forward_agent: true) }

      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute

      expect(output).to include("ForwardAgent yes")
    end

    it "turns on x11 forwarding when it is configured" do
      allow(machine).to receive(:ssh_info) { ssh_info.merge(forward_x11: true) }

      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute

      expect(output).to include("ForwardX11 yes")
    end

    it "handles multiple private key paths" do
      allow(machine).to receive(:ssh_info) { ssh_info.merge(private_key_path: ["foo", "bar"]) }

      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute

      expect(output).to include("IdentityFile foo")
      expect(output).to include("IdentityFile bar")
    end

    it "puts quotes around an identityfile path if it has a space" do
      allow(machine).to receive(:ssh_info) { ssh_info.merge(private_key_path: ["with a space"]) }
      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute

      expect(output).to include('IdentityFile "with a space"')
    end

    it "omits IdentitiesOnly when keys_only is false" do
      allow(machine).to receive(:ssh_info) { ssh_info.merge(keys_only: false) }

      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute

      expect(output).not_to include('IdentitiesOnly')
    end

    it "omits StrictHostKeyChecking and UserKnownHostsFile when paranoid is true" do
      allow(machine).to receive(:ssh_info) { ssh_info.merge(paranoid: true) }

      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute

      expect(output).not_to include('StrictHostKeyChecking ')
      expect(output).not_to include('UserKnownHostsFile ')
    end

    it "formats windows paths if windows" do
      allow(machine).to receive(:ssh_info) { ssh_info.merge(private_key_path: ["C:\\path\\to\\vagrant\\home.key"]) }
      allow(Vagrant::Util::Platform).to receive(:format_windows_path).and_return("/home/vagrant/home.key")
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)

      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute
      expect(output).to include('IdentityFile /home/vagrant/home.key')
    end
  end
end
