# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"
require_relative "../../../../../../plugins/providers/docker/action/compare_synced_folders"

describe VagrantPlugins::DockerProvider::Action::CompareSyncedFolders do
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
    let(:cached) { {:docker=>{"/vagrant"=>{:guestpath=>"/vagrant", :hostpath=>"/home/hashicorp/code/vagrant-sandbox", :disabled=>false, :__vagrantfile=>true}}} }
    let(:fresh) { {:docker=>{"/vagrant"=>{:guestpath=>"/vagrant", :hostpath=>".", :disabled=>false, :__vagrantfile=>true}}} }

    let(:existing) { {"/vagrant"=>"/home/hashicorp/code/vagrant-sandbox"} }


    it "calls the next action in the chain" do
      allow(machine.provider).to receive(:host_vm?).and_return(false)
      called = false
      app = ->(*args) { called = true }

      action = described_class.new(app, env)
      action.call(env)

      expect(called).to eq(true)
    end

    context "invalid or existing entries" do
      let(:cached) { {:docker=>{"/vagrant"=>{:guestpath=>"/not-real", :hostpath=>"/home/hashicorp/code/vagrant-sandbox", :disabled=>false, :__vagrantfile=>true}}} }
      let(:fresh) { {:docker=>{"/vagrant"=>{:guestpath=>"/vagrant", :hostpath=>".", :disabled=>false, :__vagrantfile=>true}}} }
      it "shows a warning" do
        allow(machine.provider).to receive(:host_vm?).and_return(false)

        called = false
        app = ->(*args) { called = true }
        action = described_class.new(app, env)

        expect(action).to receive(:synced_folders).
          with(machine, cached: true).and_return(cached)
        expect(action).to receive(:synced_folders).
          with(machine).and_return(fresh)

        expect(machine.ui).to receive(:warn)

        action.call(env)
        expect(called).to eq(true)
      end
    end

    it "shows no warning comparing synced folders" do
      allow(machine.provider).to receive(:host_vm?).and_return(false)

      called = false
      app = ->(*args) { called = true }
      action = described_class.new(app, env)

      expect(action).to receive(:synced_folders).
        with(machine, cached: true).and_return(cached)
      expect(action).to receive(:synced_folders).
        with(machine).and_return(fresh)

      action.call(env)
      expect(machine.ui).not_to receive(:warn)
      expect(called).to eq(true)
    end
  end
end
