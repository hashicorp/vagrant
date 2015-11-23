require File.expand_path("../../../base", __FILE__)

require "vagrant/util/presence"

describe Vagrant::Util::Presence do
  subject { described_class }

  describe "#presence" do
    it "returns false for nil" do
      expect(subject.presence(nil)).to be(false)
    end

    it "returns false for false" do
      expect(subject.presence(false)).to be(false)
    end

    it "returns false for an empty string" do
      expect(subject.presence("")).to be(false)
    end

    it "returns false for a string with null bytes" do
      expect(subject.presence("\u0000")).to be(false)
    end

    it "returns false for an empty array" do
      expect(subject.presence([])).to be(false)
    end

    it "returns false for an array with nil values" do
      expect(subject.presence([nil, nil])).to be(false)
    end

    it "returns false for an empty hash" do
      expect(subject.presence({})).to be(false)
    end

    it "returns true for true" do
      expect(subject.presence(true)).to be(true)
    end

    it "returns the object for an object" do
      obj = Object.new
      expect(subject.presence(obj)).to be(obj)
    end

    it "returns the class for a class" do
      expect(subject.presence(String)).to be(String)
    end
  end
end
