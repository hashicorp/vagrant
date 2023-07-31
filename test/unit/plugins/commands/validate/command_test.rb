# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../base"
require_relative "../../../../../plugins/commands/validate/command"

describe VagrantPlugins::CommandValidate::Command do
  include_context "unit"
  include_context "command plugin helpers"

  let(:vagrantfile_content){ "" }
  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile(vagrantfile_content)
    env.create_vagrant_env
  end

  let(:action_runner) { double("action_runner") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  let(:argv)   { [] }

  before(:all) do
    I18n.load_path << Vagrant.source_root.join("plugins/commands/port/locales/en.yml")
    I18n.reload!
  end

  subject { described_class.new(argv, iso_env) }

  describe "#execute" do
    context "validating configs" do
      let(:vagrantfile_content) do
          <<-VF
          Vagrant.configure("2") do |config|
            config.vm.box = "hashicorp/precise64"
            config.vm.synced_folder ".", "/vagrant", disabled: true
          end
          VF
      end
      it "validates correct Vagrantfile" do
        expect(machine).to receive(:action_raw) do |name, action, env|
          expect(name).to eq(:config_validate)
          expect(action).to eq(Vagrant::Action::Builtin::ConfigValidate)
          expect(env).to eq({})
        end
        expect(iso_env.ui).to receive(:info).with(any_args) { |message, _|
          expect(message).to include("Vagrantfile validated successfully.")
        }

        expect(subject.execute).to eq(0)
      end
    end

    context "invalid configs" do
      let(:vagrantfile_content) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.bix = "hashicorp/precise64"
          config.vm.synced_folder ".", "/vagrant", disabled: true
        end
        VF
      end
      it "validates the configuration" do
        expect { subject.execute }.to raise_error(Vagrant::Errors::ConfigInvalid) { |err|
          expect(err.message).to include("The following settings shouldn't exist: bix")
        }
      end
    end

    context "valid configs for multiple vms" do
      let(:vagrantfile_content) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.box = "hashicorp/precise64"
          config.vm.synced_folder ".", "/vagrant", disabled: true

          config.vm.define "test" do |vm|
            vm.vm.provider :virtualbox
          end

          config.vm.define "machine" do |vm|
            vm.vm.provider :virtualbox
          end
        end
        VF
      end
      it "validates correct Vagrantfile of all vms" do
        expect(machine).to receive(:action_raw) do |name, action, env|
          expect(name).to eq(:config_validate)
          expect(action).to eq(Vagrant::Action::Builtin::ConfigValidate)
          expect(env).to eq({})
        end
        expect(iso_env.ui).to receive(:info).with(any_args) { |message, _|
          expect(message).to include("Vagrantfile validated successfully.")
        }

        expect(subject.execute).to eq(0)
      end
    end

    context "an invalid config for some vms" do
      let(:vagrantfile_content) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.box = "hashicorp/precise64"
          config.vm.synced_folder ".", "/vagrant", disabled: true

          config.vm.define "test" do |vm|
            vm.vm.provider :virtualbox
          end

          config.vm.define "machine" do |vm|
            vm.vm.not_provider :virtualbox
          end
        end
        VF
      end
      it "validates the configuration of all vms" do
        expect(machine).to receive(:action_raw) do |name, action, env|
          expect(name).to eq(:config_validate)
          expect(action).to eq(Vagrant::Action::Builtin::ConfigValidate)
          expect(env).to eq({})
        end

        expect { subject.execute }.to raise_error(Vagrant::Errors::ConfigInvalid) { |err|
          expect(err.message).to include("The following settings shouldn't exist: not_provider")
        }
      end
    end

    context "with the ignore provider flag" do
      let(:argv) { ["--ignore-provider"]}
      let(:vagrantfile_content) do
        <<-VF
        Vagrant.configure("2") do |config|
          config.vm.box = "hashicorp/precise64"
          config.vm.synced_folder ".", "/vagrant", disabled: true

          config.vm.define "test" do |vm|
            vm.vm.hostname = "test"
            vm.vm.provider :virtualbox do |v|
              v.not_a_real_option = true
            end
          end
        end
        VF
      end
      it "ignores provider specific configurations with the flag" do
        allow(subject).to receive(:mockup_providers!).and_return("")
        allow(FileUtils).to receive(:remove_entry).and_return(true)
        expect(iso_env.ui).to receive(:info).with(any_args) { |message, _|
          expect(message).to include("Vagrantfile validated successfully.")
        }

        expect(machine).to receive(:action_raw) do |name, action, env|
          expect(name).to eq(:config_validate)
          expect(action).to eq(Vagrant::Action::Builtin::ConfigValidate)
          expect(env).to eq({:ignore_provider=>true})
        end

        expect(subject.execute).to eq(0)
      end
    end

    context "no vagrantfile" do
      let(:vagrantfile_content){ "" }
      let(:env) { isolated_environment.create_vagrant_env }
      subject { described_class.new(argv, env) }
      it "throws an exception if there's no Vagrantfile" do
        expect { subject.execute }.to raise_error(Vagrant::Errors::NoEnvironmentError)
      end
    end
  end
end
