require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/winrm_config/command")
require Vagrant.source_root.join("plugins/communicators/winrm/helper")

describe VagrantPlugins::CommandWinRMConfig::Command do
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
  let(:winrm_info) {{
    host: "testhost.vagrant.dev",
    port: 1234
  }}
  let(:config) {
    double("config",
      winrm: double("winrm-config", username: "vagrant", password: "vagrant"),
      rdp: double("rdp-config", port: 9876)
    )
  }

  subject { described_class.new(argv, iso_env) }

  before do
    allow(machine).to receive(:config).and_return(config)
    allow(VagrantPlugins::CommunicatorWinRM::Helper).to receive(:winrm_info).and_return(winrm_info)
    allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
  end

  describe "execute" do
    it "prints out the winrm config for the given machine" do
      output = ""
      allow(subject).to receive(:safe_puts) do |data|
        output += data if data
      end

      subject.execute

      expect(output).to eq(<<-WINRMCONFIG)
Host #{machine.name}
  HostName testhost.vagrant.dev
  User vagrant
  Password vagrant
  Port 1234
  RDPPort 9876
      WINRMCONFIG
    end

    context "with host option set" do
      let(:argv) { ["--host", "my-host"]}

      it "should use custom host name in config output" do
        output = ""
        allow(subject).to receive(:safe_puts) do |data|
          output += data if data
        end

        subject.execute

        expect(output).to eq(<<-WINRMCONFIG)
Host my-host
  HostName testhost.vagrant.dev
  User vagrant
  Password vagrant
  Port 1234
  RDPPort 9876
      WINRMCONFIG
      end
    end
  end
end
