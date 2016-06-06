require_relative "../../../../base"

describe "VagrantPlugins::GuestAmazon::Cap::Flavor" do
  let(:caps) do
    VagrantPlugins::GuestAmazon::Plugin
      .components
      .guest_capabilities[:amazon]
  end

  let(:machine) { double("machine") }

  describe ".flavor" do
    let(:cap) { caps.get(:flavor) }

    it "returns rhel" do
      expect(cap.flavor(machine)).to be(:rhel)
    end
  end
end
