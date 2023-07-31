# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/action/import")

describe VagrantPlugins::HyperV::Action::Import do
  let(:app){ double("app") }
  let(:env){ {ui: ui, machine: machine} }
  let(:ui){ Vagrant::UI::Silent.new }
  let(:provider){ double("provider", driver: driver) }
  let(:driver){ double("driver") }
  let(:machine){ double("machine", provider: provider, provider_config: provider_config, box: box, data_dir: data_dir, name: "machname") }
  let(:provider_config){
    double("provider_config",
      linked_clone: false,
      vmname: "VMNAME"
    )
  }
  let(:box){ double("box", directory: box_directory) }
  let(:box_directory){ double("box_directory") }
  let(:data_dir){ double("data_dir") }
  let(:vm_dir){ double("vm_dir") }
  let(:hd_dir){ double("hd_dir") }

  let(:subject){ described_class.new(app, env) }

  before do
    allow(app).to receive(:call)
    allow(box_directory).to receive(:join).with("Virtual Machines").and_return(vm_dir)
    allow(box_directory).to receive(:join).with("Virtual Hard Disks").and_return(hd_dir)
    allow(vm_dir).to receive(:directory?).and_return(true)
    allow(vm_dir).to receive(:each_child).and_yield(Pathname.new("file.txt"))
    allow(hd_dir).to receive(:directory?).and_return(true)
    allow(hd_dir).to receive(:each_child).and_yield(Pathname.new("file.txt"))
    allow(driver).to receive(:has_vmcx_support?).and_return(true)
    allow(data_dir).to receive(:join).and_return(data_dir)
    allow(data_dir).to receive(:to_s).and_return("DATA_DIR_PATH")
    allow(driver).to receive(:import).and_return("id" => "VMID")
    allow(machine).to receive(:id=)
  end

  context "with missing virtual machines directory" do
    before{ expect(vm_dir).to receive(:directory?).and_return(false) }

    it "should raise an error" do
      expect{ subject.call(env) }.to raise_error(VagrantPlugins::HyperV::Errors::BoxInvalid)
    end
  end

  context "with missing hard disks directory" do
    before{ expect(hd_dir).to receive(:directory?).and_return(false) }

    it "should raise an error" do
      expect{ subject.call(env) }.to raise_error(VagrantPlugins::HyperV::Errors::BoxInvalid)
    end
  end

  context "with missing configuration file" do
    before do
      allow(hd_dir).to receive(:each_child).and_yield(Pathname.new("image.vhd"))
    end

    it "should raise an error" do
      expect{ subject.call(env) }.to raise_error(VagrantPlugins::HyperV::Errors::BoxInvalid)
    end
  end

  context "with missing image file" do
    before do
      allow(vm_dir).to receive(:each_child).and_yield(Pathname.new("config.xml"))
    end

    it "should raise an error" do
      expect{ subject.call(env) }.to raise_error(VagrantPlugins::HyperV::Errors::BoxInvalid)
    end
  end

  context "with image and config files" do
    before do
      allow(vm_dir).to receive(:each_child).and_yield(Pathname.new("config.xml"))
      allow(hd_dir).to receive(:each_child).and_yield(Pathname.new("image.vhd"))
    end

    it "should call the app on success" do
      expect(app).to receive(:call)
      subject.call(env)
    end

    it "should request import via the driver" do
      expect(driver).to receive(:import).and_return("id" => "VMID")
      subject.call(env)
    end

    it "should set the machine ID after import" do
      expect(machine).to receive(:id=).with("VMID")
      subject.call(env)
    end

    context "with no vmcx support" do
      before do
        expect(driver).to receive(:has_vmcx_support?).and_return(false)
      end

      it "should match XML config file" do
        subject.call(env)
      end

      it "should not match VMCX config file" do
        expect(vm_dir).to receive(:each_child).and_yield(Pathname.new("config.vmcx"))
        expect{ subject.call(env) }.to raise_error(VagrantPlugins::HyperV::Errors::BoxInvalid)
      end
    end

    context "with vmcx support" do
      before do
        expect(driver).to receive(:has_vmcx_support?).and_return(true)
      end

      it "should match XML config file" do
        subject.call(env)
      end

      it "should match VMCX config file" do
        expect(vm_dir).to receive(:each_child).and_yield(Pathname.new("config.vmcx"))
        subject.call(env)
      end
    end
  end
end
