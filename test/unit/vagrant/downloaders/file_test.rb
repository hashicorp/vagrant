require File.expand_path("../../../base", __FILE__)

require "tempfile"

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

    it "should match files where the path needs to be expanded" do
      old_home = ENV["HOME"]
      begin
        # Create a temporary file
        temp = Tempfile.new("vagrant")

        # Set our home directory to be this directory so we can use
        # "~" paths
        ENV["HOME"] = File.dirname(temp.path)

        # Test that we can find the temp file
        described_class.match?("~/#{File.basename(temp.path)}").should be
      ensure
        ENV["HOME"] = old_home
      end
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

    it "should find files that use shell expansions" do
      old_home = ENV["HOME"]
      begin
        # Create a temporary file
        temp = Tempfile.new("vagrant")

        # Set our home directory to be this directory so we can use
        # "~" paths
        ENV["HOME"] = File.dirname(temp.path)

        # Test that we can find the temp file
        expect { instance.prepare("~/#{File.basename(temp.path)}") }.
          to_not raise_error
      ensure
        ENV["HOME"] = old_home
      end
    end
  end

  describe "downloading" do
    it "should copy the source to the destination" do
      pending "setup paths"
    end
  end
end
