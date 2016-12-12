require_relative "../../../../base"

describe "VagrantPlugins::GuestSUSE::Cap::NetworkScriptsDir" do
  let(:caps) do
    VagrantPlugins::GuestSUSE::Plugin
      .components
      .guest_capabilities[:suse]
  end

  let(:machine) { double("machine") }

  describe ".network_scripts_dir" do
    let(:cap) { caps.get(:network_scripts_dir) }

    it "runs /etc/sysconfig/network" do
      expect(cap.network_scripts_dir(machine)).to eq("/etc/sysconfig/network")
    end
  end
end
