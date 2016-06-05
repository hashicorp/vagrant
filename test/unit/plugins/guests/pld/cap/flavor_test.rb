require_relative "../../../../base"

describe "VagrantPlugins::GuestPld::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestPld::Plugin
      .components
      .guest_capabilities[:pld]
  end

  let(:machine) { double("machine") }

  describe ".flavor" do
    let(:cap) { caps.get(:flavor) }

    let(:name) { "banana-rama.example.com" }

    it "is pld" do
      expect(cap.flavor(machine)).to be(:pld)
    end
  end
end
