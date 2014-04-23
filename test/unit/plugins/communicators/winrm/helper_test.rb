require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/communicators/winrm/helper")

describe VagrantPlugins::CommunicatorWinRM::Helper do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    test_iso_env.vagrantfile("")
    test_iso_env.create_vagrant_env
  end
  let(:test_iso_env) { isolated_environment }

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  subject { described_class }

  describe ".winrm_address" do
    before do
      machine.config.winrm.host = nil
    end

    it "returns the configured host if set" do
      machine.config.winrm.host = "foo"
      expect(subject.winrm_address(machine)).to eq("foo")
    end

    it "returns the SSH info host if available" do
      machine.stub(ssh_info: { host: "bar" })
      expect(subject.winrm_address(machine)).to eq("bar")
    end

    it "raise an exception if it can't detect a host" do
      machine.stub(ssh_info: nil)
      expect { subject.winrm_address(machine) }.
        to raise_error(VagrantPlugins::CommunicatorWinRM::Errors::WinRMNotReady)
    end
  end

  describe ".winrm_port" do
    it "returns the configured port if no guest port set" do
      machine.config.winrm.port = 22
      machine.config.winrm.guest_port = nil

      expect(subject.winrm_port(machine)).to eq(22)
    end

    it "returns a forwarded port that matches the guest port" do
      machine.config.winrm.port = 22
      machine.config.winrm.guest_port = 2222
      machine.config.vm.network "forwarded_port", host: 1234, guest: 2222

      expect(subject.winrm_port(machine)).to eq(1234)
    end

    it "uses the provider capability if it exists" do
      machine.config.winrm.port = 22
      machine.config.winrm.guest_port = 2222
      machine.config.vm.network "forwarded_port", host: 1234, guest: 2222

      machine.provider.stub(:capability?).with(:forwarded_ports).and_return(true)
      machine.provider.stub(:capability).with(:forwarded_ports).and_return({
        1234 => 4567,
        2456 => 2222,
      })

      expect(subject.winrm_port(machine)).to eq(2456)
    end
  end
end
