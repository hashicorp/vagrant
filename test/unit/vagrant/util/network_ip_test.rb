require File.expand_path("../../../base", __FILE__)

require "vagrant/util/network_ip"

describe Vagrant::Util::NetworkIP do
  let(:klass) do
    Class.new do
      include Vagrant::Util::NetworkIP
    end
  end

  subject { klass.new }

  describe "#network_address" do
    it "calculates it properly" do
      expect(subject.network_address("192.168.2.234", "255.255.255.0")).to eq("192.168.2.0")
    end

    it "calculates it properly with integer submask" do
      expect(subject.network_address("192.168.2.234", "24")).to eq("192.168.2.0")
    end

    it "calculates it properly with integer submask" do
      expect(subject.network_address("192.168.2.234", 24)).to eq("192.168.2.0")
    end

    it "calculates it properly for IPv6" do
      expect(subject.network_address("fde4:8dba:82e1::c4", "64")).to eq("fde4:8dba:82e1::")
    end

    it "calculates it properly for IPv6" do
      expect(subject.network_address("fde4:8dba:82e1::c4", 64)).to eq("fde4:8dba:82e1::")
    end

    it "calculates it properly for IPv6 for string mask" do
      expect(subject.network_address("fde4:8dba:82e1::c4", "ffff:ffff:ffff:ffff::")).to eq("fde4:8dba:82e1::")
    end

    it "recovers from invalid netmask" do
      # The mask function will produce an error for ruby >= 2.5
      # If using a version of ruby that produces and error, then
      # test to ensure `subject.network_address` produces expected
      # results.
      begin
        IPAddr.new("192.168.2.234").mask("1.2.3.4")
      rescue IPAddr::InvalidPrefixError
        expect(subject.network_address("192.168.2.234", "1.2.3.4")).to eq("192.168.2.0")
      end
    end
  end
end
