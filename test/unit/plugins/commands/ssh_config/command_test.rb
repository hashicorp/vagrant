require File.expand_path("../../../../base", __FILE__)

describe "VagrantPlugins::CommandSSHConfig::Command" do
  include_context "unit"
  include_context "virtualbox"

  let(:described_class) { Vagrant.plugin("2").manager.commands[:"ssh-config"] }

  let(:argv)     { [] }
  let(:env)      { Vagrant::Environment.new }
  let(:machine)  { double("Vagrant::Machine", :name => nil) }
  let(:ssh_info) {{
    :host             => "testhost.vagrant.dev",
    :port             => 1234,
    :username         => "testuser",
    :private_key_path => [],
    :forward_agent    => false,
    :forward_x11      => false
  }}

  subject { described_class.new(argv, env) }

  before do
    subject.stub(:with_target_vms) { |&block| block.call machine }
  end

  describe "execute" do
    it "prints out the ssh config for the given machine" do
      machine.stub(:ssh_info) { ssh_info }
      subject.should_receive(:safe_puts).with(<<-SSHCONFIG)
Host vagrant
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
