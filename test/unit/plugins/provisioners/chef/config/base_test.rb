require_relative "../../../../base"

require Vagrant.source_root.join("plugins/provisioners/chef/config/base")

describe VagrantPlugins::Chef::Config::Base do
  include_context "unit"

  subject { described_class.new }

  let(:machine) { double("machine") }

  describe "#binary_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.binary_path).to be(nil)
    end
  end

  describe "#binary_env" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.binary_env).to be(nil)
    end
  end

  describe "#install" do
    it "defaults to true" do
      subject.finalize!
      expect(subject.install).to be(true)
    end

    it "is converted to a symbol" do
      subject.install = "force"
      subject.finalize!
      expect(subject.install).to eq(:force)
    end
  end

  describe "#log_level" do
    it "defaults to :info" do
      subject.finalize!
      expect(subject.log_level).to be(:info)
    end

    it "is converted to a symbol" do
      subject.log_level = "foo"
      subject.finalize!
      expect(subject.log_level).to eq(:foo)
    end
  end

  describe "#prerelease" do
    it "defaults to true" do
      subject.finalize!
      expect(subject.prerelease).to be(false)
    end
  end

  describe "#version" do
    it "defaults to :latest" do
      subject.finalize!
      expect(subject.version).to eq(:latest)
    end

    it "converts the string 'latest' to a symbol" do
      subject.version = "latest"
      subject.finalize!
      expect(subject.version).to eq(:latest)
    end
  end

  describe "#installer_download_path" do
    it "defaults to nil" do
      subject.finalize!
      expect(subject.installer_download_path).to be(nil)
    end
  end
end
