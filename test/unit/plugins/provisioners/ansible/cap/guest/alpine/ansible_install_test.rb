# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../../../base"
require_relative "../shared/pip_ansible_install_examples"

require Vagrant.source_root.join("plugins/provisioners/ansible/cap/guest/alpine/ansible_install")

describe VagrantPlugins::Ansible::Cap::Guest::Alpine::AnsibleInstall do
  include_context "unit"

  subject { VagrantPlugins::Ansible::Cap::Guest::Alpine::AnsibleInstall }

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
    it "install required alpine packages for pip" do
      expect(communicator).to receive(:sudo).once.ordered.
        with("apk add --update --no-cache python3")
      expect(communicator).to receive(:sudo).once.ordered.
        with("if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi")
      expect(communicator).to receive(:sudo).once.ordered.
        with("apk add --update --no-cache --virtual .build-deps python3-dev libffi-dev openssl-dev build-base")

      subject.pip_setup(machine)
    end
  end

  describe "#ansible_install" do

    it_behaves_like "Ansible setup via pip"

    describe "when install_mode is :default (or unknown)" do
      it "installs ansible with 'apk' package manager" do
        expect(communicator).to receive(:sudo).once.ordered.
            with("apk add --update --no-cache python3 ansible")
        expect(communicator).to receive(:sudo).once.ordered.
            with("if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi")
        expect(communicator).to receive(:sudo).once.ordered.
            with("if [ ! -e /usr/bin/pip ]; then ln -sf pip3 /usr/bin/pip ; fi")

        subject.ansible_install(machine, :default, "", "", "")
      end
    end
  end

end
