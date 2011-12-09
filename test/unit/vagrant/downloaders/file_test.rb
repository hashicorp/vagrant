require File.expand_path("../../../base", __FILE__)

describe Vagrant::Downloaders::File do
  let(:ui) { double("ui") }
  let(:instance) { described_class.new(ui) }

  describe "matching" do
    it "should match an existing file" do
      described_class.match?(__FILE__).should be
    end

    it "should not match non-existent files" do
      described_class.match?(File.join(__FILE__, "nowaywaywaywayayway")).should_not be
    end
  end

  describe "preparing" do
    it "should raise an exception if the file does not exist" do
      path = File.join(__FILE__, "nopenopenope")
      File.exist?(path).should_not be

      expect { instance.prepare(path) }.to raise_error(Vagrant::Errors::DownloaderFileDoesntExist)
    end

    it "should raise an exception if the file is a directory" do
      path = File.dirname(__FILE__)
      File.should be_directory(path)

      expect { instance.prepare(path) }.to raise_error(Vagrant::Errors::DownloaderFileDoesntExist)
    end
  end

  describe "downloading" do
    it "should copy the source to the destination" do
      pending "setup paths"
    end
  end
end
