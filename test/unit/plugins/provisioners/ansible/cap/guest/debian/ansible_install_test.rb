# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../../../base"
require_relative "../shared/pip_ansible_install_examples"


require Vagrant.source_root.join("plugins/provisioners/ansible/cap/guest/debian/ansible_install")


describe VagrantPlugins::Ansible::Cap::Guest::Debian::AnsibleInstall do
  include_context "unit"

  subject { VagrantPlugins::Ansible::Cap::Guest::Debian::AnsibleInstall }

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
    allow(communicator).to receive(:test).and_return(false)
  end

  describe "#ansible_install" do

    it_behaves_like "Ansible setup via pip on Debian-based systems"

    describe "when install_mode is :default (or unknown)" do
      it "installs ansible with apt package manager" do
        install_backports_if_wheezy_release = <<INLINE_CRIPT
CODENAME=`lsb_release -cs`
if [ x$CODENAME == 'xwheezy' ]; then
  echo 'deb http://http.debian.net/debian wheezy-backports main' > /etc/apt/sources.list.d/wheezy-backports.list
fi
INLINE_CRIPT

        expect(communicator).to receive(:sudo).once.ordered.with(install_backports_if_wheezy_release)
        expect(communicator).to receive(:sudo).once.ordered.with("apt-get update -y -qq")
        expect(communicator).to receive(:sudo).once.ordered.with("DEBIAN_FRONTEND=noninteractive apt-get install -y -qq --option \"Dpkg::Options::=--force-confold\" ansible")

        subject.ansible_install(machine, :default, "", "", "")
      end
    end
  end

end
