require File.expand_path("../../../base", __FILE__)

require "vagrant/util/numeric"

describe Vagrant::Util::Numeric do
  include_context "unit"
  before(:each) { described_class.reset! }
  subject { described_class }

  describe "#string_to_bytes" do
    it "converts a string to the proper bytes" do
      bytes = subject.string_to_bytes("10KB")
      expect(bytes).to eq(10240)
    end

    it "returns nil if the given string is the wrong format" do
      bytes = subject.string_to_bytes("10 Kilobytes")
      expect(bytes).to eq(nil)
    end
  end
end
