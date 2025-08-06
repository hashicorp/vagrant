# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../../../../base"

require Vagrant.source_root.join("plugins/provisioners/ansible/cap/guest/redhat/ansible_install")

describe VagrantPlugins::Ansible::Cap::Guest::RedHat::AnsibleInstall do
  include_context "unit"

  subject { VagrantPlugins::Ansible::Cap::Guest::RedHat::AnsibleInstall }

  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:communicator) { double("comm") }
  let(:dist) { ".el8" }
  let(:epel) { 1 }

  before do
    allow(machine).to receive(:communicate).and_return(communicator)
    allow(communicator).to receive(:execute).with("rpm -E %dist").and_yield(:stdout, dist)
  end

  describe "#ansible_epel_download_url" do
    it "returns the correct EPEL download URL for RHEL-like versions below 10" do
      expect(subject.ansible_epel_download_url(machine)).to eq("https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm")
    end

    context "for RHEL-like versions 10 and above" do
      let(:dist) { ".el10" }
      it "returns the correct EPEL download URL" do
        out = subject.ansible_epel_download_url(machine)
        expect(out).to eq("https://dl.fedoraproject.org/pub/epel/epel-release-latest-10.noarch.rpm")
      end
    end
  end

  describe "#ansible_rpm_install" do
    before do
      expect(communicator).to receive(:test).with("/usr/bin/which -s dnf").and_return(false)
      expect(communicator).to receive(:execute).with("yum repolist epel | grep -q epel", error_check: false).and_return(epel)
      expect(communicator).to receive(:sudo).with("yum -y --enablerepo=epel install ansible")
    end

    it "installs ansible package, when epel is not installed" do
      expect(communicator).to receive(:sudo).with("sudo rpm -i https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm")
      subject.ansible_rpm_install(machine)
    end

    context "when the EPEL repository is already installed" do
      let(:epel) { 0 }
      it "installs ansible package" do
        expect(communicator).to_not receive(:sudo).with("sudo rpm -i https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm")
        subject.ansible_rpm_install(machine)
      end
    end

  end

end
