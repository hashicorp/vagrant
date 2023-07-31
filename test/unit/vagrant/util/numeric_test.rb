# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

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

  describe "bytes to megabytes" do
    it "converts bytes to megabytes" do
      expect(subject.bytes_to_megabytes(1000000)).to eq(0.95)
    end
  end
end
