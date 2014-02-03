require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/docker/config")

describe VagrantPlugins::Docker::Config do
  subject { described_class.new }

  describe "#build_image" do
    it "stores them" do
      subject.build_image("foo")
      subject.build_image("bar", foo: :bar)
      subject.finalize!
      expect(subject.build_images.length).to eql(2)
      expect(subject.build_images[0]).to eql(["foo", {}])
      expect(subject.build_images[1]).to eql(["bar", { foo: :bar }])
    end
  end

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

  describe "#run" do
    it "runs the given image" do
      subject.run("foo")

      subject.finalize!
      expect(subject.containers).to eql({
        "foo" => {
          daemonize: true,
          image: "foo",
        }
      })
    end

    it "can not daemonize" do
      subject.run("foo", daemonize: false)

      subject.finalize!
      expect(subject.containers).to eql({
        "foo" => {
          daemonize: false,
          image: "foo",
        }
      })
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
