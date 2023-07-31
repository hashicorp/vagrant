# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vagrant")

describe VagrantPlugins::Kernel_V2::VagrantConfig do
  subject { described_class.new }

  let(:machine){ double("machine") }

  describe "#host" do
    it "defaults to :detect" do
      subject.finalize!
      expect(subject.host).to eq(:detect)
    end

    it "symbolizes" do
      subject.host = "foo"
      subject.finalize!
      expect(subject.host).to eq(:foo)
    end
  end

  describe "#sensitive" do
    after{ Vagrant::Util::CredentialScrubber.reset! }

    it "accepts string value" do
      subject.sensitive = "test"
      subject.finalize!
      expect(subject.sensitive).to eq("test")
    end

    it "accepts array of values" do
      subject.sensitive = ["test1", "test2"]
      subject.finalize!
      expect(subject.sensitive).to eq(["test1", "test2"])
    end

    it "does not accept non-string values" do
      subject.sensitive = 1
      subject.finalize!
      result = subject.validate(machine)
      expect(result).to be_a(Hash)
      expect(result.values).not_to be_empty
    end

    it "registers single sensitive value to be scrubbed" do
      subject.sensitive = "test"
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with("test")
      subject.finalize!
    end

    it "registers multiple sensitive values to be scrubbed" do
      subject.sensitive = ["test1", "test2"]
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with("test1")
      expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with("test2")
      subject.finalize!
    end
  end

  describe "#plugins" do
    it "converts string into hash of plugins" do
      subject.plugins = "vagrant-plugin"
      subject.finalize!
      expect(subject.plugins).to be_a(Hash)
    end

    it "converts array of strings into hash of plugins" do
      subject.plugins = ["vagrant-plugin", "vagrant-other-plugin"]
      subject.finalize!
      expect(subject.plugins).to be_a(Hash)
      expect(subject.plugins.keys).to eq(["vagrant-plugin", "vagrant-other-plugin"])
    end

    it "does not convert hash" do
      plugins = {"vagrant-plugin" => {}}
      subject.plugins = plugins
      subject.finalize
      expect(subject.plugins).to eq(plugins)
    end

    it "converts array of mixed strings and hashes" do
      subject.plugins = ["vagrant-plugin", {"vagrant-other-plugin" => {:version => "1"}}]
      subject.finalize!
      expect(subject.plugins["vagrant-plugin"]).to eq({})
      expect(subject.plugins["vagrant-other-plugin"]).to eq({"version" => "1"})
    end

    it "generates a validation error when incorrect type is provided" do
      subject.plugins = 0
      subject.finalize!
      result = subject.validate(machine)
      expect(result.values).not_to be_empty
    end

    it "generates a validation error when invalid option is provided" do
      subject.plugins = {"vagrant-plugin" => {"badkey" => true}}
      subject.finalize!
      result = subject.validate(machine)
      expect(result.values).not_to be_empty
    end

    it "generates a validation error when options are incorrect type" do
      subject.plugins = {"vagrant-plugin" => 1}
      subject.finalize!
      result = subject.validate(machine)
      expect(result.values).not_to be_empty
    end
  end
end
