require_relative "../../../../base"

describe "VagrantPlugins::GuestLinux::Cap::NetworkInterfaces" do
  let(:caps) do
    VagrantPlugins::GuestLinux::Plugin
      .components
      .guest_capabilities[:linux]
  end

  let(:machine) { double("machine") }
  let(:comm) { VagrantTests::DummyCommunicator::Communicator.new(machine) }

  before do
    allow(machine).to receive(:communicate).and_return(comm)
  end

  after do
    comm.verify_expectations!
  end

  describe ".network_interfaces" do
    let(:cap){ caps.get(:network_interfaces) }

    it "sorts discovered classic interfaces" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "eth1\neth2\neth0")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["eth0", "eth1", "eth2"])
    end

    it "sorts discovered predictable network interfaces" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "enp0s8\nenp0s3\nenp0s5")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["enp0s3", "enp0s5", "enp0s8"])
    end

    it "sorts discovered classic interfaces naturally" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "eth1\neth2\neth12\neth0\neth10")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["eth0", "eth1", "eth2", "eth10", "eth12"])
    end

    it "sorts discovered predictable network interfaces naturally" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "enp0s8\nenp0s3\nenp0s5\nenp0s10\nenp1s3")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["enp0s3", "enp0s5", "enp0s8", "enp0s10", "enp1s3"])
    end

    it "sorts ethernet devices discovered with classic naming first in list" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "eth1\neth2\ndocker0\nbridge0\neth0")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["eth0", "eth1", "eth2", "bridge0", "docker0"])
    end

    it "sorts ethernet devices discovered with predictable network interfaces naming first in list" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "enp0s8\ndocker0\nenp0s3\nbridge0\nenp0s5")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["enp0s3", "enp0s5", "enp0s8", "bridge0", "docker0"])
    end

    it "sorts ethernet devices discovered with predictable network interfaces naming first in list with less" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "enp0s3\nenp0s8\ndocker0")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["enp0s3", "enp0s8", "docker0"])
    end

    it "does not include ethernet devices aliases within prefix device listing" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "eth1\neth2\ndocker0\nbridge0\neth0\ndocker1\neth0:0")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["eth0", "eth1", "eth2", "bridge0", "docker0", "docker1", "eth0:0"])
    end

    it "does not include ethernet devices aliases within prefix device listing with dot separators" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "eth1\neth2\ndocker0\nbridge0\neth0\ndocker1\neth0.1@eth0")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["eth0", "eth1", "eth2", "bridge0", "docker0", "docker1", "eth0.1@eth0"])
    end

    it "properly sorts non-consistent device name formats" do
      expect(comm).to receive(:sudo).twice.and_yield(:stdout, "eth0\neth1\ndocker0\nveth437f7f9\nveth06b3e44\nveth8bb7081")
      result = cap.network_interfaces(machine)
      expect(result).to eq(["eth0", "eth1", "docker0", "veth8bb7081", "veth437f7f9", "veth06b3e44"])
    end
  end
end
