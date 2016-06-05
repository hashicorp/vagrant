require_relative "../../../../base"

describe "VagrantPlugins::GuestPld::Cap::NetworkScriptsDir" do
  let(:caps) do
    VagrantPlugins::GuestPld::Plugin
      .components
      .guest_capabilities[:pld]
  end

  let(:machine) { double("machine") }

  describe ".network_scripts_dir" do
    let(:cap) { caps.get(:network_scripts_dir) }

    let(:name) { "banana-rama.example.com" }

    it "is /etc/sysconfig/interfaces" do
      expect(cap.network_scripts_dir(machine)).to eq("/etc/sysconfig/interfaces")
    end
  end
end
