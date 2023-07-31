# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/commands/winrm/command")

describe VagrantPlugins::CommandWinRM::Command do
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
  let(:communicator) { double("communicator") }

  let(:argv)     { [] }
  let(:config) {
    double("config",
      vm: double("vm-config", communicator: communicator_name))
  }
  let(:communicator_name) { :winrm }

  subject { described_class.new(argv, iso_env) }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(machine).to receive(:config).and_return(config)
    allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
    allow(communicator).to receive(:execute)
  end

  it "should exit successfully when no command is provided" do
    expect(subject.execute).to eq(0)
  end

  context "with command provided" do
    let(:argv){ ["-c", "dir"] }

    it "should execute the command via the communicator" do
      expect(communicator).to receive(:execute).with("dir", any_args)
      subject.execute
    end

    it "should execute with default shell" do
      expect(communicator).to receive(:execute).with(anything, hash_including(shell: :powershell))
      subject.execute
    end

    it "should execute without elevated privileges" do
      expect(communicator).to receive(:execute).with(anything, hash_including(elevated: false))
      subject.execute
    end

    context "with elevated option set" do
      let(:argv) { ["-c", "dir", "-e"] }

      it "should execute with elevated privileges" do
        expect(communicator).to receive(:execute).with(anything, hash_including(elevated: true))
        subject.execute
      end
    end

    context "with shell option set" do
      let(:argv) { ["-c", "dir", "-s", "cmd"] }

      it "should execute with custom shell" do
        expect(communicator).to receive(:execute).with(anything, hash_including(shell: :cmd))
        subject.execute
      end
    end
  end

  context "with multiple command provided" do
    let(:argv) { ["-c", "dir", "-c", "dir2"] }

    it "should execute multiple commands via the communicator" do
      expect(communicator).to receive(:execute).with("dir", any_args)
      expect(communicator).to receive(:execute).with("dir2", any_args)
      subject.execute
    end
  end

  context "with invalid communicator configured" do
    let(:communicator_name) { :ssh }

    it "should raise an error" do
      expect { subject.execute }.to raise_error(Vagrant::Errors::WinRMInvalidCommunicator)
    end
  end
end
