require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/provisioners/docker/config")

describe VagrantPlugins::DockerProvisioner::Config do
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

  describe "#merge" do
    it "has all images to pull" do
      subject.pull_images("1")

      other = described_class.new
      other.pull_images("2", "3")

      result = subject.merge(other)
      expect(result.images.to_a.sort).to eq(
        ["1", "2", "3"])
    end

    it "has all the containers to run" do
      subject.run("foo", image: "bar", daemonize: false)
      subject.run("bar")

      other = described_class.new
      other.run("foo", image: "foo")

      result = subject.merge(other)
      result.finalize!

      cs     = result.containers
      expect(cs.length).to eq(2)
      expect(cs["foo"]).to eq({
        auto_assign_name: true,
        image: "foo",
        daemonize: false,
        restart: "always",
      })
      expect(cs["bar"]).to eq({
        auto_assign_name: true,
        image: "bar",
        daemonize: true,
        restart: "always",
      })
    end

    it "has all the containers to build" do
      subject.build_image("foo")

      other = described_class.new
      other.build_image("bar")

      result = subject.merge(other)
      result.finalize!

      images = result.build_images
      expect(images.length).to eq(2)
      expect(images[0]).to eq(["foo", {}])
      expect(images[1]).to eq(["bar", {}])
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
          auto_assign_name: true,
          daemonize: true,
          image: "foo",
          restart: "always",
        }
      })
    end

    it "can not auto assign name" do
      subject.run("foo", auto_assign_name: false)

      subject.finalize!
      expect(subject.containers).to eql({
        "foo" => {
          auto_assign_name: false,
          daemonize: true,
          image: "foo",
          restart: "always",
        }
      })
    end

    it "can not daemonize" do
      subject.run("foo", daemonize: false)

      subject.finalize!
      expect(subject.containers).to eql({
        "foo" => {
          auto_assign_name: true,
          daemonize: false,
          image: "foo",
          restart: "always",
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
