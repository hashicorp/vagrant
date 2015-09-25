require_relative "../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/config")

describe VagrantPlugins::HyperV::Config do
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
  describe "#disks_config" do
    it "can be set" do
      dc = [[{ 'name' =>"d1", 'size' => "100"},
             { 'name' =>"d2", 'size' => "50"}],
            [{ 'path' =>"D:\\test.vhdx"}]]

      subject.disks_config = dc
      subject.finalize!
      expect(subject.disks_config).to eq(dc)
    end
  end
  describe "#guest_integration_service" do
    it "can be set" do
      subject.guest_integration_service = true
      subject.finalize!
      expect(subject.guest_integration_service).to eq(true)
    end
  end
  describe "#time_sync" do
    it "can be set" do
      subject.time_sync = false
      subject.finalize!
      expect(subject.time_sync).to eq(false)
    end
  end
  describe "#auto_stop_action" do
    it "can be set" do
      subject.auto_stop_action = "ShutDown"
      subject.finalize!
      expect(subject.auto_stop_action).to eq("ShutDown")
    end
  end
end
