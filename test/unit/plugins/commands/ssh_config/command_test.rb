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
    :host             => "testhost.vagrant.dev",
    :port             => 1234,
    :username         => "testuser",
    :private_key_path => [],
    :forward_agent    => false,
    :forward_x11      => false
  }}

  subject { described_class.new(argv, iso_env) }

  before do
    machine.stub(ssh_info: ssh_info)
    subject.stub(:with_target_vms) { |&block| block.call machine }
  end

  describe "execute" do
    it "prints out the ssh config for the given machine" do
      subject.should_receive(:safe_puts).with(<<-SSHCONFIG)
Host #{machine.name}
  HostName testhost.vagrant.dev
  User testuser
  Port 1234
  UserKnownHostsFile /dev/null
  StrictHostKeyChecking no
  PasswordAuthentication no
  IdentitiesOnly yes
  LogLevel FATAL
      SSHCONFIG
      subject.execute
    end

    it "turns on agent forwarding when it is configured" do
      machine.stub(:ssh_info) { ssh_info.merge(:forward_agent => true) }
      subject.should_receive(:safe_puts).with { |ssh_config|
        ssh_config.should include("ForwardAgent yes")
      }
      subject.execute
    end

    it "turns on x11 forwarding when it is configured" do
      machine.stub(:ssh_info) { ssh_info.merge(:forward_x11 => true) }
      subject.should_receive(:safe_puts).with { |ssh_config|
        ssh_config.should include("ForwardX11 yes")
      }
      subject.execute
    end

    it "handles multiple private key paths" do
      machine.stub(:ssh_info) { ssh_info.merge(:private_key_path => ["foo", "bar"]) }
      subject.should_receive(:safe_puts).with { |ssh_config|
        ssh_config.should include("IdentityFile foo")
        ssh_config.should include("IdentityFile bar")
      }
      subject.execute
    end

    it "puts quotes around an identityfile path if it has a space" do
      machine.stub(:ssh_info) { ssh_info.merge(:private_key_path => ["with a space"]) }
      subject.should_receive(:safe_puts).with { |ssh_config|
        ssh_config.should include('IdentityFile "with a space"')
      }
      subject.execute
    end
  end
end
