# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../../../base"

require Vagrant.source_root.join("plugins/provisioners/ansible/cap/guest/pip/pip")

describe VagrantPlugins::Ansible::Cap::Guest::Pip do
  include_context "unit"

  subject { VagrantPlugins::Ansible::Cap::Guest::Pip }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:communicator) { double("comm") }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(communicator).to receive(:execute).and_return(true)
  end

  describe "#get_pip" do
    describe "when no pip_install_cmd argument is provided" do
      it "installs pip using the default command" do
        expect(communicator).to receive(:execute).
          with("curl https://bootstrap.pypa.io/get-pip.py | sudo python")

        subject.get_pip(machine)
      end
    end

    describe "when pip_install_cmd argument is provided" do
      it "runs the supplied argument instead of default" do
        pip_install_cmd = "foo"

        expect(communicator).to receive(:execute).with(pip_install_cmd)

        subject.get_pip(machine, pip_install_cmd)
      end

      it "installs pip using the default command if the argument is empty" do
        pip_install_cmd = ""

        expect(communicator).to receive(:execute).
          with("curl https://bootstrap.pypa.io/get-pip.py | sudo python")

        subject.get_pip(machine, pip_install_cmd)
      end

      it "installs pip using the default command if the argument is nil" do
        expect(communicator).to receive(:execute).
          with("curl https://bootstrap.pypa.io/get-pip.py | sudo python")

        subject.get_pip(machine, nil)
      end
    end
  end
end