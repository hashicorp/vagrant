require File.expand_path("../../../base", __FILE__)

describe Vagrant::Downloaders::SCP do
  let(:ui) { double("ui") }
  let(:instance) { described_class.new(ui) }

  describe "matching" do
    it "should match SCP URLs" do
      described_class.match?("scp://user@example.com/foo.box").should be
      described_class.match?("scp://example.com/fox.box").should be
      described_class.match?("scp://user:password@example.com//tmp/foo.box").should be
      described_class.match?("scp://user@example.com:2222/foo.box").should be
    end

    it "should not match URLs with any other scheme" do
      described_class.match?("ssh://example.com/foo.box").should_not be
      described_class.match?("http://example.com:8500/foo.box").should_not be
      described_class.match?("https://example.com:8500/foo.box").should_not be
    end
  end

  describe "downloading" do
    # Integration tests only.
  end
end
