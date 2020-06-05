require File.expand_path("../../../base", __FILE__)

require "vagrant/util/validate_netmask"

describe Vagrant::Util::ValidateNetmask do
  include_context "unit"
  subject { described_class }

  describe ".validate" do
    it "validates valid netmask" do
      masks = [
        "0.0.0.0",
        "255.255.255.255",
        "255.255.255.0",
        "255.255.0.0",
        "255.0.0.0",
        "255.255.192.0",
        "255.252.0.0",
        "192.0.0.0"
      ]
      masks.each do |mask|
        subject.validate(mask)
      end
    end

    it "raises an error for invalid netmask" do
      masks = [
        "255.255.192.255",
        "1.2.3.4",
        "192.0.0.0.0"
      ]
      masks.each do |mask|
        expect { subject.validate(mask) }.to raise_error(Vagrant::Errors::InvalidNetMask)
      end
    end
  end
end
