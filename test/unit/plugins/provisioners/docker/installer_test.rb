# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/docker/provisioner")

describe VagrantPlugins::DockerProvisioner::Installer do
  include_context "unit"
  subject { described_class.new(machine) }

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

    allow(communicator).to receive(:ready?).and_return(true)
    allow(communicator).to receive(:test).with(/Linux/).and_return(true)
  end

  describe "#ensure_installed" do
    it "returns if docker capability not present" do
      allow(machine).to receive_message_chain(:guest, :capability?).with(:docker_installed).and_return(false)
      expect(subject.ensure_installed()).to eq(false)
    end

    it "does not install docker if already present" do
      expect(communicator).to receive(:test).with(/docker/, {:sudo=>true}).and_return(true)
      allow(communicator).to receive(:test).and_return(true)
      expect(subject.ensure_installed()).to eq(true)
    end

    it "installs docker if not present" do
      allow(machine).to receive_message_chain(:guest, :capability?).with(:docker_installed).and_return(true)
      allow(machine).to receive_message_chain(:guest, :capability).with(:docker_install).and_return(false)
      allow(machine).to receive_message_chain(:guest, :capability).with(:docker_installed).and_return(false)

      # Expect to raise error since we are mocking out the test for docker install to return false
      expect {subject.ensure_installed()}.to raise_error(VagrantPlugins::DockerProvisioner::DockerError)
    end
  end

end
