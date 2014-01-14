require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/docker/config")

describe VagrantPlugins::Docker::Config do
  subject { described_class.new }

  describe "#images" do
    it "stores them in a set" do
      subject.images = ["1", "1", "2"]
      subject.finalize!
      expect(subject.images.to_a.sort).to eql(["1", "2"])
    end

    it "overrides previously set images" do
      subject.images = ["3"]
      subject.images = ["1", "1", "2"]
      subject.finalize!
      expect(subject.images.to_a.sort).to eql(["1", "2"])
    end
  end

  describe "#pull_images" do
    it "adds images to the list of images to build" do
      subject.pull_images("1")
      subject.pull_images("2", "3")
      subject.finalize!
      expect(subject.images.to_a.sort).to eql(["1", "2", "3"])
    end
  end

  describe "#version" do
    it "defaults to latest" do
      subject.finalize!
      expect(subject.version).to eql(:latest)
    end

    it "converts to a symbol" do
      subject.version = "v27"
      subject.finalize!
      expect(subject.version).to eql(:v27)
    end
  end
end
