# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/config")

describe VagrantPlugins::HyperV::Config do

  let(:machine){ double("machine", ui: ui) }
  let(:ui){ Vagrant::UI::Silent.new }

  describe "#ip_address_timeout" do
    it "can be set" do
      subject.ip_address_timeout = 180
      subject.finalize!
      expect(subject.ip_address_timeout).to eq(180)
    end
    it "defaults to a number" do
      subject.finalize!
      expect(subject.ip_address_timeout).to eq(120)
    end
  end

  describe "#vlan_id" do
    it "can be set" do
      subject.vlan_id = 100
      subject.finalize!
      expect(subject.vlan_id).to eq(100)
    end
  end

  describe "#mac" do
    it "can be set" do
      subject.mac = "001122334455"
      subject.finalize!
      expect(subject.mac).to eq("001122334455")
    end
  end

  describe "#vmname" do
    it "can be set" do
      subject.vmname = "test"
      subject.finalize!
      expect(subject.vmname).to eq("test")
    end
  end

  describe "#memory" do
    it "can be set" do
      subject.memory = 512
      subject.finalize!
      expect(subject.memory).to eq(512)
    end
  end

  describe "#maxmemory" do
    it "can be set" do
      subject.maxmemory = 1024
      subject.finalize!
      expect(subject.maxmemory).to eq(1024)
    end
  end

  describe "#cpus" do
    it "can be set" do
      subject.cpus = 2
      subject.finalize!
      expect(subject.cpus).to eq(2)
    end
  end

  describe "#vmname" do
    it "can be set" do
      subject.vmname = "custom"
      subject.finalize!
      expect(subject.vmname).to eq("custom")
    end
  end

  describe "#differencing_disk" do
    it "is false by default" do
      subject.finalize!
      expect(subject.differencing_disk).to eq(false)
    end

    it "can be set" do
      subject.differencing_disk = true
      subject.finalize!
      expect(subject.differencing_disk).to eq(true)
    end

    it "should set linked_clone" do
      subject.differencing_disk = true
      subject.finalize!
      expect(subject.differencing_disk).to eq(true)
      expect(subject.linked_clone).to eq(true)
    end

    it "should provide a deprecation warning when set" do
      expect(ui).to receive(:warn)
      subject.differencing_disk = true
      subject.finalize!
      subject.validate(machine)
    end
  end

  describe "#linked_clone" do
    it "is false by default" do
      subject.finalize!
      expect(subject.linked_clone).to eq(false)
    end

    it "can be set" do
      subject.linked_clone = true
      subject.finalize!
      expect(subject.linked_clone).to eq(true)
    end

    it "should set differencing_disk" do
      subject.linked_clone = true
      subject.finalize!
      expect(subject.linked_clone).to eq(true)
      expect(subject.differencing_disk).to eq(true)
    end
  end

  describe "#auto_start_action" do
    it "should be Nothing by default" do
      subject.finalize!
      expect(subject.auto_start_action).to eq("Nothing")
    end

    it "can be set" do
      subject.auto_start_action = "Start"
      subject.finalize!
      expect(subject.auto_start_action).to eq("Start")
    end

    it "does not accept invalid values" do
      subject.auto_start_action = "Invalid"
      subject.finalize!
      result = subject.validate(machine)
      expect(result["Hyper-V"]).not_to be_empty
    end
  end

  describe "#auto_stop_action" do
    it "should be ShutDown by default" do
      subject.finalize!
      expect(subject.auto_stop_action).to eq("ShutDown")
    end

    it "can be set" do
      subject.auto_stop_action = "Save"
      subject.finalize!
      expect(subject.auto_stop_action).to eq("Save")
    end

    it "does not accept invalid values" do
      subject.auto_stop_action = "Invalid"
      subject.finalize!
      result = subject.validate(machine)
      expect(result["Hyper-V"]).not_to be_empty
    end
  end

  describe "#enable_checkpoints" do
    it "is true by default" do
      subject.finalize!
      expect(subject.enable_checkpoints).to eq(true)
    end

    it "can be set" do
      subject.enable_checkpoints = false
      subject.finalize!
      expect(subject.enable_checkpoints).to eq(false)
    end

    it "is enabled automatically when enable_automatic_checkpoints is enabled" do
      subject.enable_checkpoints = false
      subject.enable_automatic_checkpoints = true
      subject.finalize!
      expect(subject.enable_checkpoints).to eq(true)
    end
  end

  describe "#enable_automatic_checkpoints" do
    it "is false by default" do
      subject.finalize!
      expect(subject.enable_automatic_checkpoints).to eq(false)
    end

    it "can be set" do
      subject.enable_checkpoints = true
      subject.finalize!
      expect(subject.enable_checkpoints).to eq(true)
    end
  end

  describe "#enable_virtualization_extensions" do
    it "is false by default" do
      subject.finalize!
      expect(subject.enable_virtualization_extensions).to eq(false)
    end

    it "can be set" do
      subject.enable_virtualization_extensions = true
      subject.finalize!
      expect(subject.enable_virtualization_extensions).to eq(true)
    end
  end

  describe "#vm_integration_services" do
    it "is empty by default" do
      subject.finalize!
      expect(subject.vm_integration_services).to be_empty
    end

    it "accepts new entries" do
      subject.vm_integration_services["entry"] = "value"
      subject.finalize!
      expect(subject.vm_integration_services["entry"]).to eq("value")
    end

    it "does not accept non-Hash types" do
      subject.vm_integration_services = "value"
      subject.finalize!
      result = subject.validate(machine)
      expect(result["Hyper-V"]).not_to be_empty
    end

    it "accepts boolean values within Hash" do
      subject.vm_integration_services["custom"] = true
      subject.finalize!
      result = subject.validate(machine)
      expect(result["Hyper-V"]).to be_empty
    end

    it "does not accept non-boolean values within Hash" do
      subject.vm_integration_services["custom"] = "value"
      subject.finalize!
      result = subject.validate(machine)
      expect(result["Hyper-V"]).not_to be_empty
    end
  end


  describe "#enable_enhanced_session_mode" do
    it "is false by default" do
      subject.finalize!
      expect(subject.enable_enhanced_session_mode).to eq(false)
    end

    it "can be set" do
      subject.enable_enhanced_session_mode = true
      subject.finalize!
      expect(subject.enable_enhanced_session_mode).to eq(true)
    end
  end
end
