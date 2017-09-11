require_relative "../../../../base"

describe "VagrantPlugins::GuestALT::Cap::NetworkScriptsDir" do
  let(:caps) do
    VagrantPlugins::GuestALT::Plugin
      .components
      .guest_capabilities[:alt]
  end

  let(:machine) { double("machine") }

  describe ".network_scripts_dir" do
    let(:cap) { caps.get(:network_scripts_dir) }

    let(:name) { "banana-rama.example.com" }

    it "is /etc/net" do
      expect(cap.network_scripts_dir(machine)).to eq("/etc/net")
    end
  end
end
