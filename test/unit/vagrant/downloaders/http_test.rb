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

    it "should not match file:// URIs" do
      described_class.match?("file://#{__FILE__}").should_not be
    end

    it "should not match file:// URIs" do
      described_class.match?("file://#{__FILE__}").should_not be
    end
  end

  describe "redirects" do

    it "should show error when redirects limit reached" do
      expect { instance.download!('http://google.com', 'w', 0) }.
        to raise_error(Vagrant::Errors::DownloaderRedirectLimit)
    end

    it "constant 301 redirect should raise error" do
      pending
    end
  end

  describe "downloading" do
    # Integration tests only.
  end
end
