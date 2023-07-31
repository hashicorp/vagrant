# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/provisioner/chef_solo")

describe VagrantPlugins::Chef::Provisioner::ChefSolo do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:config)  { double("config") }

  subject { described_class.new(machine, config) }

  before do
    allow(config).to receive(:node_name)
    allow(config).to receive(:node_name=)
  end

  describe "#expanded_folders" do
    before { allow(subject).to receive(:windows?).and_return(true) }

    it "handles the default Windows provisioning path" do
      allow(config).to receive(:provisioning_path).and_return(nil)
      remote_path = subject.expanded_folders([[:vm, "cookbooks-1"]])[0][2]
      expect(remote_path).to eq("/vagrant-chef/cookbooks-1")
    end

    it "removes drive letter prefix from path" do
      allow(config).to receive(:provisioning_path).and_return(nil)
      expect(File).to receive(:expand_path).and_return("C:/vagrant-chef/cookbooks-1")
      result = subject.expanded_folders([[:vm, "cookbooks-1"]])
      remote_path = result[0][2]
      expect(remote_path).to eq("/vagrant-chef/cookbooks-1")
    end

  end

  describe "#expanded_folders" do
    it "expands Windows absolute provisioning path with relative path" do
      provisioning_path = "C:/vagrant-chef-1"
      unexpanded_path = "cookbooks-1"

      allow(config).to receive(:provisioning_path).and_return(provisioning_path)
      remote_path = subject.expanded_folders([[:vm, unexpanded_path]])[0][2]

      expect(remote_path).to eq("/vagrant-chef-1/cookbooks-1")
    end

    it "expands Windows absolute provisioning path with absolute path" do
      provisioning_path = "C:/vagrant-chef-1"
      unexpanded_path = "/cookbooks-1"

      allow(config).to receive(:provisioning_path).and_return(provisioning_path)
      remote_path = subject.expanded_folders([[:vm, unexpanded_path]])[0][2]

      expect(remote_path).to eq("/cookbooks-1")
    end

    it "expands Windows absolute provisioning path with Windows absolute path" do
      provisioning_path = "C:/vagrant-chef-1"
      unexpanded_path = "D:/cookbooks-1"

      allow(config).to receive(:provisioning_path).and_return(provisioning_path)
      remote_path = subject.expanded_folders([[:vm, unexpanded_path]])[0][2]

      expect(remote_path).to eq("/cookbooks-1")
    end

    it "expands absolute provisioning path with Windows absolute path" do
      provisioning_path = "/vagrant-chef-1"
      unexpanded_path = "D:/cookbooks-1"

      allow(config).to receive(:provisioning_path).and_return(provisioning_path)
      remote_path = subject.expanded_folders([[:vm, unexpanded_path]])[0][2]

      expect(remote_path).to eq("/cookbooks-1")
    end
  end
end
