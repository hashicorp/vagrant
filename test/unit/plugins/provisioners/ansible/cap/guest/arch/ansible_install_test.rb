# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../../../base"
require_relative "../shared/pip_ansible_install_examples"

require Vagrant.source_root.join("plugins/provisioners/ansible/cap/guest/arch/ansible_install")

describe VagrantPlugins::Ansible::Cap::Guest::Arch::AnsibleInstall do
  include_context "unit"

  subject { VagrantPlugins::Ansible::Cap::Guest::Arch::AnsibleInstall }

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

  describe "#pip_setup" do
    it "install required Arch packages and call Cap::Guest::Pip::get_pip" do
      pip_install_cmd = "foo"

      expect(communicator).to receive(:sudo).once.ordered.
        with("pacman -Syy --noconfirm")
      expect(communicator).to receive(:sudo).once.ordered.
        with("pacman -S --noconfirm base-devel curl git python")
      expect(VagrantPlugins::Ansible::Cap::Guest::Pip).to receive(:get_pip).once.ordered.
        with(machine, pip_install_cmd)

      subject.pip_setup(machine, pip_install_cmd)
    end
  end

  describe "#ansible_install" do

    it_behaves_like "Ansible setup via pip"

    describe "when install_mode is :default (or unknown)" do
      it "installs ansible with 'pacman' package manager" do
        expect(communicator).to receive(:sudo).once.ordered.
          with("pacman -Syy --noconfirm")
        expect(communicator).to receive(:sudo).once.ordered.
          with("pacman -S --noconfirm ansible")

        subject.ansible_install(machine, :default, "", "", "")
      end
    end
  end

end
