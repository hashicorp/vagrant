require_relative "../../../../base"

describe "VagrantPlugins::GuestRedHat::Cap::NetworkScriptsDir" do
  let(:caps) do
    VagrantPlugins::GuestRedHat::Plugin
      .components
      .guest_capabilities[:redhat]
  end

  let(:machine) { double("machine") }

  describe ".network_scripts_dir" do
    let(:cap) { caps.get(:network_scripts_dir) }

    let(:name) { "banana-rama.example.com" }

    it "is /etc/sysconfig/network-scripts" do
      expect(cap.network_scripts_dir(machine)).to eq("/etc/sysconfig/network-scripts")
    end
  end
end
