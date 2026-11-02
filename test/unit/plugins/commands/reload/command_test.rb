# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/commands/reload/command")

describe VagrantPlugins::CommandReload::Command do
  include_context "unit"

  let(:entry_klass) { Vagrant::MachineIndex::Entry }
  let(:argv)     { [] }
  let(:vagrantfile_content){ "" }
  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile(vagrantfile_content)
    env.create_vagrant_env
  end

  subject { described_class.new(argv, iso_env) }

  let(:action_runner) { double("action_runner") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:machine2) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  def new_entry(name)
    entry_klass.new.tap do |e|
      e.name = name
      e.vagrantfile_path = "/bar"
    end
  end

  before do
    allow(iso_env).to receive(:action_runner).and_return(action_runner)
    allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
  end

  context "with no argument" do
    let(:vagrantfile_content) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.define "app"
          config.vm.define "db"
        end
        VF
    end

    it "should reload all vms" do
      allow(subject).to receive(:with_target_vms) { |&block|
        block.call machine
        block.call machine2
      }
      expect(machine).to receive(:action) do |name, opts|
        expect(name).to eq(:reload)
      end
      expect(machine2).to receive(:action) do |name, opts|
        expect(name).to eq(:reload)
      end

      expect(subject.execute).to eq(0)
    end
  end

  context "with an argument" do
    let(:vagrantfile_content) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.define "app"
          config.vm.define "db"
        end
        VF
    end
    let(:argv) { ["app"] }

    it "should reload a vm" do
      expect(machine).to receive(:action) do |name, opts|
        expect(name).to eq(:reload)
      end

      expect(subject.execute).to eq(0)
    end
  end

  context "with the force flag" do
    let(:vagrantfile_content) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.define "app"
          config.vm.define "db"
        end
        VF
    end
    let(:argv) { ["--force"] }
    it "should reload a vm" do
      expect(machine).to receive(:action) do |name, opts|
        expect(opts).to include(force_halt: true)
        expect(name).to eq(:reload)
      end

      expect(subject.execute).to eq(0)
    end
  end
end
