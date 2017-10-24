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
      allow(machine).to receive(:ssh_info).and_return({ host: "bar" })
      expect(subject.winrm_address(machine)).to eq("bar")
    end

    it "raise an exception if it can't detect a host" do
      allow(machine).to receive(:ssh_info).and_return(nil)
      expect { subject.winrm_address(machine) }.
        to raise_error(VagrantPlugins::CommunicatorWinRM::Errors::WinRMNotReady)
    end

    it "raise an exception if it detects an empty host ip" do
      allow(machine).to receive(:ssh_info).and_return({ host: "" })
      expect { subject.winrm_address(machine) }.
        to raise_error(VagrantPlugins::CommunicatorWinRM::Errors::WinRMNotReady)
    end

    it "raise a WinRMNotReady exception if it detects an unset host ip" do
      allow(machine).to receive(:ssh_info).and_return({ host: nil })
      expect { subject.winrm_address(machine) }.
        to raise_error(VagrantPlugins::CommunicatorWinRM::Errors::WinRMNotReady)
    end

    it "raise an exception if it detects an APIPA" do
      allow(machine).to receive(:ssh_info).and_return({ host: "169.254.123.123" })
      expect { subject.winrm_address(machine) }.
        to raise_error(VagrantPlugins::CommunicatorWinRM::Errors::WinRMNotReady)
    end
  end

  describe ".winrm_info" do
    before do
      allow(machine.provider).to receive(:capability?)
        .with(:winrm_info).and_return(false)
      allow(subject).to receive(:winrm_address).and_return(nil)
      allow(subject).to receive(:winrm_port).and_return(nil)
    end

    it "returns default info if no capability" do
      allow(subject).to receive(:winrm_address).and_return("bar")
      allow(subject).to receive(:winrm_port).and_return(45)

      result = subject.winrm_info(machine)
      expect(result[:host]).to eq("bar")
      expect(result[:port]).to eq(45)
    end

    it "raises an exception if capability returns nil" do
      allow(machine.provider).to receive(:capability?)
        .with(:winrm_info).and_return(true)
      allow(machine.provider).to receive(:capability)
        .with(:winrm_info).and_return(nil)

      expect { subject.winrm_info(machine) }.
        to raise_error(VagrantPlugins::CommunicatorWinRM::Errors::WinRMNotReady)
    end

    it "returns the proper information if set" do
      allow(machine.provider).to receive(:capability?)
        .with(:winrm_info).and_return(true)
      allow(machine.provider).to receive(:capability).with(:winrm_info).and_return({
        host: "foo",
        port: 12,
      })

      result = subject.winrm_info(machine)
      expect(result[:host]).to eq("foo")
      expect(result[:port]).to eq(12)
    end

    it "defaults information if capability doesn't set it" do
      allow(machine.provider).to receive(:capability?)
        .with(:winrm_info).and_return(true)
      allow(machine.provider).to receive(:capability).with(:winrm_info).and_return({})

      allow(subject).to receive(:winrm_address).and_return("bar")
      allow(subject).to receive(:winrm_port).and_return(45)

      result = subject.winrm_info(machine)
      expect(result[:host]).to eq("bar")
      expect(result[:port]).to eq(45)
    end
  end

  describe ".winrm_port" do
    it "returns the configured port if no guest port set" do
      machine.config.winrm.port = 22
      machine.config.winrm.guest_port = nil

      expect(subject.winrm_port(machine)).to eq(22)
    end

    it "returns the configured guest port if non local" do
      machine.config.winrm.port = 22
      machine.config.winrm.guest_port = 2222
      machine.config.vm.network "forwarded_port", host: 1234, guest: 2222

      expect(subject.winrm_port(machine, false)).to eq(2222)
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

      allow(machine.provider).to receive(:capability?).with(:forwarded_ports).and_return(true)
      allow(machine.provider).to receive(:capability).with(:forwarded_ports).and_return({
        1234 => 4567,
        2456 => 2222,
      })

      expect(subject.winrm_port(machine)).to eq(2456)
    end
  end

  describe ".winrm_info_invalid?" do
    it "returns true if it can't detect a host" do
      allow(machine).to receive(:ssh_info).and_return(nil)
      expect(subject).to be_winrm_info_invalid(machine.ssh_info)
    end

    it "returns true if it detects an empty host ip" do
      allow(machine).to receive(:ssh_info).and_return({ host: "" })
      expect(subject).to be_winrm_info_invalid(machine.ssh_info)
    end

    it "returns true if it detects an unset host ip" do
      allow(machine).to receive(:ssh_info).and_return({ host: nil })
      expect(subject).to be_winrm_info_invalid(machine.ssh_info)
    end

    it "returns true if it detects an APIPA" do
      allow(machine).to receive(:ssh_info).and_return({ host: "169.254.123.123" })
      expect(subject).to be_winrm_info_invalid(machine.ssh_info)
    end

    it "returns false if the IP is valid" do
      allow(machine).to receive(:ssh_info).and_return({ host: "192.168.123.123" })
      expect(subject).not_to be_winrm_info_invalid(machine.ssh_info)
    end
  end
end
