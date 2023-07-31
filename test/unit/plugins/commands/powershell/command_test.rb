# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/powershell/command")

describe VagrantPlugins::CommandPS::Command do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest)   { double("guest") }
  let(:host)    { double("host") }
  let(:config)  {
    double("config",
      vm: double("vm", communicator: communicator_name),
      winrm: double("winrm", username: winrm_username, password: winrm_password)
    )
  }
  let(:communicator_name) { :winrm }
  let(:winrm_info) { {host: winrm_host, port: winrm_port} }
  let(:winrm_username) { double("winrm_username") }
  let(:winrm_password) { double("winrm_password") }
  let(:winrm_host) { double("winrm_host") }
  let(:winrm_port) { double("winrm_port") }

  let(:remoting_ready_result) { {} }

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  let(:argv) { [] }

  subject { described_class.new(argv, iso_env) }

  before do
    allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
    allow(iso_env).to receive(:host).and_return(host)
    allow(host).to receive(:capability?).with(:ps_client).and_return(true)

    allow(machine.communicate).to receive(:ready?).and_return(true)
    allow(machine).to receive(:config).and_return(config)

    allow(VagrantPlugins::CommunicatorWinRM::Helper).to receive(:winrm_info).and_return(winrm_info)
    allow(subject).to receive(:ready_ps_remoting_for).and_return(remoting_ready_result)
    allow(host).to receive(:capability).with(:ps_client, any_args)

    # Ignore loading up translations
    allow_any_instance_of(Vagrant::Errors::VagrantError).to receive(:translate_error)
  end

  describe "#execute" do
    context "when communicator is not ready" do
      before { expect(machine.communicate).to receive(:ready?).and_return(false) }

      it "should raise error that machine is not created" do
        expect { subject.execute }.to raise_error(Vagrant::Errors::VMNotCreatedError)
      end
    end

    context "when communicator is not winrm" do
      let(:communicator_name) { :ssh }

      context "when command is provided" do
        let(:argv) { ["-c", "command"] }

        it "should raise an error that winrm is not ready" do
          expect { subject.execute }.to raise_error(VagrantPlugins::CommunicatorWinRM::Errors::WinRMNotReady)
        end
      end

      context "when no command is provided" do
        it "should create a powershell session" do
          expect(host).to receive(:capability).with(:ps_client, any_args)
          subject.execute
        end
      end
    end

    context "when host does not support ps_client" do
      before { allow(host).to receive(:capability?).with(:ps_client).and_return(false) }

      context "when no command is provided" do
        it "should raise an error for unsupported host" do
          expect { subject.execute }.to raise_error(VagrantPlugins::CommandPS::Errors::HostUnsupported)
        end
      end

      context "when command is provided" do
        let(:argv) { ["-c", "command"] }

        it "should execute command when command is provided" do
          expect(machine.communicate).to receive(:execute).with("command", any_args).and_return(0)
          subject.execute
        end
      end
    end

    context "with command provided" do
      let(:argv) { ["-c", "command"] }

      it "executes the command on the guest" do
        expect(machine.communicate).to receive(:execute).with("command", any_args).and_return(0)
        subject.execute
      end

      context "with elevated flag" do
        let(:argv) { ["-e", "-c", "command"] }

        it "should execute the command with elevated option" do
          expect(machine.communicate).to receive(:execute).
            with("command", hash_including(elevated: true)).and_return(0)
          subject.execute
        end
      end
    end

    context "with elevated flag and no command" do
      let(:argv) { ["-e"] }

      it "should raise error that command must be provided" do
        expect { subject.execute }.to raise_error(VagrantPlugins::CommandPS::Errors::ElevatedNoCommand)
      end
    end

    it "should start a new session" do
      expect(host).to receive(:capability).with(:ps_client, any_args)
      subject.execute
    end

    context "when setup returns PreviousTrustedHosts" do
      let(:remoting_ready_result) { {"PreviousTrustedHosts" => true} }

      it "should reset the powershell remoting" do
        expect(subject).to receive(:reset_ps_remoting_for)
        subject.execute
      end
    end
  end
end
