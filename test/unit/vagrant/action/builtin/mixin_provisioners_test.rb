# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/kernel_v2/config/vm")

require "vagrant/action/builtin/mixin_provisioners"

describe Vagrant::Action::Builtin::MixinProvisioners do
  include_context "unit"

  let(:sandbox) { isolated_environment }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    sandbox.vagrantfile("")
    sandbox.create_vagrant_env
  end

  let(:provisioner_config){ double("provisioner_config", name: nil) }
  let(:provisioner_one) do
    prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("spec-test", :shell)
    prov.config = provisioner_config
    prov
  end
  let(:provisioner_two) do
    prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("spec-test", :shell)
    prov.config = provisioner_config
    prov
  end
  let(:provisioner_three) do
    prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new(nil, :shell)
    provisioner_config = double("provisioner_config", name: "my_shell")
    prov.config = provisioner_config
    prov
  end

  let(:provisioner_instances) { [provisioner_one,provisioner_two,provisioner_three] }

  let(:ui) { Vagrant::UI::Silent.new }
  let(:vm) { double("vm", provisioners: provisioner_instances) }
  let(:config) { double("config", vm: vm) }
  let(:machine) { double("machine", ui: ui, config: config) }

  let(:env) {{ machine: machine, ui: machine.ui, root_path: Pathname.new(".") }}

  subject do
    Class.new do
      extend Vagrant::Action::Builtin::MixinProvisioners
    end
  end

  after do
    sandbox.close
    described_class.reset!
  end

  describe "#provisioner_instances" do
    it "returns all the instances of configured provisioners" do
      result = subject.provisioner_instances(env)
      expect(result.size).to eq(provisioner_instances.size)
      shell_one = result.first
      expect(shell_one.first).to be_a(VagrantPlugins::Shell::Provisioner)
      shell_two = result[1]
      expect(shell_two.first).to be_a(VagrantPlugins::Shell::Provisioner)
    end

    it "returns all the instances of configured provisioners" do
      result = subject.provisioner_instances(env)
      expect(result.size).to eq(provisioner_instances.size)
      shell_one = result.first
      expect(shell_one[1][:name]).to eq(:"spec-test")
      shell_two = result[1]
      expect(shell_two[1][:name]).to eq(:"spec-test")
      shell_three = result[2]
      expect(shell_three[1][:name]).to eq(:"my_shell")
    end
  end

  context "#sort_provisioner_instances" do
    describe "with no dependency provisioners" do
      it "returns the original array" do
        result = subject.provisioner_instances(env)
        expect(result.size).to eq(provisioner_instances.size)
        shell_one = result.first
        expect(shell_one.first).to be_a(VagrantPlugins::Shell::Provisioner)
        shell_two = result[1]
        expect(shell_two.first).to be_a(VagrantPlugins::Shell::Provisioner)
      end
    end

    describe "with before and after dependency provisioners" do
      let(:provisioner_config){ {} }
      let(:provisioner_root) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_before) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("before-test", :shell)
        prov.config = provisioner_config
        prov.before = "root-test"
        prov
      end
      let(:provisioner_after) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("after-test", :shell)
        prov.config = provisioner_config
        prov.after = "root-test"
        prov
      end
      let(:provisioner_instances) { [provisioner_root,provisioner_before,provisioner_after] }

      it "returns the array in the correct order" do
        result = subject.provisioner_instances(env)
        expect(result[0].last[:name]).to eq(:"before-test")
        expect(result[1].last[:name]).to eq(:"root-test")
        expect(result[2].last[:name]).to eq(:"after-test")
      end
    end

    describe "with before :each dependency provisioners" do
      let(:provisioner_config){ {} }
      let(:provisioner_root) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_root2) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root2-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_before) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("before-test", :shell)
        prov.config = provisioner_config
        prov.before = :each
        prov
      end

      let(:provisioner_instances) { [provisioner_root,provisioner_root2,provisioner_before] }

      it "puts the each shortcut provisioners in place" do
        result = subject.provisioner_instances(env)

        expect(result[0].last[:name]).to eq(:"before-test")
        expect(result[1].last[:name]).to eq(:"root-test")
        expect(result[2].last[:name]).to eq(:"before-test")
        expect(result[3].last[:name]).to eq(:"root2-test")
      end
    end

    describe "with after :each dependency provisioners" do
      let(:provisioner_config){ {} }
      let(:provisioner_root) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_root2) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root2-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_after) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("after-test", :shell)
        prov.config = provisioner_config
        prov.after = :each
        prov
      end

      let(:provisioner_instances) { [provisioner_root,provisioner_root2,provisioner_after] }

      it "puts the each shortcut provisioners in place" do
        result = subject.provisioner_instances(env)

        expect(result[0].last[:name]).to eq(:"root-test")
        expect(result[1].last[:name]).to eq(:"after-test")
        expect(result[2].last[:name]).to eq(:"root2-test")
        expect(result[3].last[:name]).to eq(:"after-test")
      end
    end

    describe "with before and after :each dependency provisioners" do
      let(:provisioner_config){ {} }
      let(:provisioner_root) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_root2) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root2-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_after) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("after-test", :shell)
        prov.config = provisioner_config
        prov.after = :each
        prov
      end
      let(:provisioner_before) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("before-test", :shell)
        prov.config = provisioner_config
        prov.before = :each
        prov
      end

      let(:provisioner_instances) { [provisioner_root,provisioner_root2,provisioner_before,provisioner_after] }

      it "puts the each shortcut provisioners in place" do
        result = subject.provisioner_instances(env)

        expect(result[0].last[:name]).to eq(:"before-test")
        expect(result[1].last[:name]).to eq(:"root-test")
        expect(result[2].last[:name]).to eq(:"after-test")
        expect(result[3].last[:name]).to eq(:"before-test")
        expect(result[4].last[:name]).to eq(:"root2-test")
        expect(result[5].last[:name]).to eq(:"after-test")
      end
    end

    describe "with before and after :all dependency provisioners" do
      let(:provisioner_config){ {} }
      let(:provisioner_root) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_root2) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("root2-test", :shell)
        prov.config = provisioner_config
        prov
      end
      let(:provisioner_after) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("after-test", :shell)
        prov.config = provisioner_config
        prov.after = :all
        prov
      end
      let(:provisioner_before) do
        prov = VagrantPlugins::Kernel_V2::VagrantConfigProvisioner.new("before-test", :shell)
        prov.config = provisioner_config
        prov.before = :all
        prov
      end

      let(:provisioner_instances) { [provisioner_root,provisioner_root2,provisioner_before,provisioner_after] }

      it "puts the each shortcut provisioners in place" do
        result = subject.provisioner_instances(env)

        expect(result[0].last[:name]).to eq(:"before-test")
        expect(result[1].last[:name]).to eq(:"root-test")
        expect(result[2].last[:name]).to eq(:"root2-test")
        expect(result[3].last[:name]).to eq(:"after-test")
      end
    end
  end
end
