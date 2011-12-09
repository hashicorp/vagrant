require File.expand_path("../../../base", __FILE__)

describe Vagrant::Downloaders::HTTP do
  let(:ui) { double("ui") }
  let(:instance) { described_class.new(ui) }

  describe "matching" do
    it "should match URLs" do
      described_class.match?("http://google.com/foo.box").should be
      described_class.match?("https://google.com/foo.box").should be
      described_class.match?("http://foo:bar@google.com/foo.box").should be
      described_class.match?("http://google.com:8500/foo.box").should be
    end
  end

  describe "downloading" do
    # Integration tests only.
  end
end
