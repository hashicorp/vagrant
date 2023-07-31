# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../../../base"
require_relative "../shared/pip_ansible_install_examples"


require Vagrant.source_root.join("plugins/provisioners/ansible/cap/guest/ubuntu/ansible_install")


describe VagrantPlugins::Ansible::Cap::Guest::Ubuntu::AnsibleInstall do
  include_context "unit"

  subject { VagrantPlugins::Ansible::Cap::Guest::Ubuntu::AnsibleInstall }

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

    it_behaves_like "Ansible setup via pip on Debian-based systems"

    describe "when install_mode is :default (or unknown)" do
      describe "#ansible_apt_install" do
        describe "installs ansible from ansible/ansible PPA repository" do

          check_if_add_apt_repository_is_present="test -x \"$(which add-apt-repository)\""

          it "first installs 'software-properties-common' package if add-apt-repository is not already present" do
            allow(communicator).to receive(:test).
              with(check_if_add_apt_repository_is_present).and_return(false)

            expect(communicator).to receive(:sudo).once.ordered.
              with("""
                  apt-get update -y -qq && \
                  DEBIAN_FRONTEND=noninteractive apt-get install -y -qq software-properties-common --option \"Dpkg::Options::=--force-confold\"
                """)
            expect(communicator).to receive(:sudo).once.ordered.
              with("""
                add-apt-repository ppa:ansible/ansible -y && \
                apt-get update -y -qq && \
                DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ansible --option \"Dpkg::Options::=--force-confold\"
              """)

            subject.ansible_install(machine, :default, "", "", "")
          end

          it "adds 'ppa:ansible/ansible' and install 'ansible' package" do
            allow(communicator).to receive(:test).
              with(check_if_add_apt_repository_is_present).and_return(true)

            expect(communicator).to receive(:sudo).
              with("""
                add-apt-repository ppa:ansible/ansible -y && \
                apt-get update -y -qq && \
                DEBIAN_FRONTEND=noninteractive apt-get install -y -qq ansible --option \"Dpkg::Options::=--force-confold\"
              """)

            subject.ansible_install(machine, :default, "", "", "")
          end

        end
      end
    end
  end

end
