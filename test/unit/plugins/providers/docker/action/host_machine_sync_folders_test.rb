# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/host_machine_sync_folders"

describe VagrantPlugins::DockerProvider::Action::HostMachineSyncFolders do
  include_context "unit"
  include_context "virtualbox"

  let(:sandbox) { isolated_environment }

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    sandbox.vagrantfile("")
    sandbox.create_vagrant_env
  end

  let(:machine) do
    iso_env.machine(iso_env.machine_names[0], :virtualbox).tap do |m|
      allow(m.provider).to receive(:driver).and_return(driver)
    end
  end

  let(:env)    {{ machine: machine, ui: machine.ui, root_path: Pathname.new(".") }}
  let(:app)    { lambda { |*args| }}
  let(:driver) { double("driver") }

  subject { described_class.new(app, env) }

  after do
    sandbox.close
  end

  describe "#call" do
    it "calls the next action in the chain" do
      allow(machine.provider).to receive(:host_vm?).and_return(false)
      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)
      action.call(env)

      expect(called).to eq(true)
    end

    context "with a host vm" do
      it "calls the next action in the chain" do
        allow(machine.provider).to receive(:host_vm?).and_return(true)
        allow(machine.provider).to receive(:host_vm).and_return(machine)
        called = false
        app = ->(*args) { called = true }

        expect(machine.provider).to receive(:host_vm_lock).and_return(true)
        action = described_class.new(app, env)
        action.call(env)

        expect(called).to eq(true)
      end
    end
  end

  describe "#setup_synced_folders" do
    it "syncs folders on the guest machine with a given id" do
      allow(Digest::MD5).to receive(:hexdigest).and_return("4e9414d72abee585b3d6263e50248e37")
      expect(machine).to receive(:action).with(:sync_folders, {:synced_folders_config => anything})
      expect(env[:machine].config.vm).to receive(:synced_folder).
        with("/var/lib/docker/docker_4e9414d72abee585b3d6263e50248e37",
             "/vagrant", anything)
      subject.send(:setup_synced_folders, machine, env)
    end
  end
end
