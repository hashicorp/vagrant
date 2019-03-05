require_relative "../base"

describe Vagrant::GoPlugin do
  describe "INSTALL_DIRECTORY constant" do
    let(:subject) { described_class.const_get(:INSTALL_DIRECTORY) }

    it "should be a String" do
      expect(subject).to be_a(String)
    end

    it "should be frozen" do
      expect(subject).to be_frozen
    end

    it "should be within the user data path" do
      expect(subject).to start_with(Vagrant.user_data_path.to_s)
    end
  end

  describe ".interface" do
    it "should return an interface instance" do
      expect(described_class.interface).to be_a(Vagrant::GoPlugin::Interface)
    end

    it "should cache the interface instance" do
      expect(described_class.interface).to be(described_class.interface)
    end
  end
end
