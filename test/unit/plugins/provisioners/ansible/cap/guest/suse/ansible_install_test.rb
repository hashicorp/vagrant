# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../../../base"
require_relative "../shared/pip_ansible_install_examples"


require Vagrant.source_root.join("plugins/provisioners/ansible/cap/guest/suse/ansible_install")


describe VagrantPlugins::Ansible::Cap::Guest::SUSE::AnsibleInstall do
  include_context "unit"

  subject { VagrantPlugins::Ansible::Cap::Guest::SUSE::AnsibleInstall }

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

  describe "#ansible_install" do

    it_behaves_like "Ansible setup via pip is not implemented"

    describe "when install_mode is :default (or unknown)" do
      it "installs ansible with 'zypper' package manager" do
        expect(communicator).to receive(:sudo).with("zypper --non-interactive --quiet install ansible")

        subject.ansible_install(machine, :default, "", "", "")
      end
    end
  end

end