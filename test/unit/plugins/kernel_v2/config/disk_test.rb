# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/disk")

describe VagrantPlugins::Kernel_V2::VagrantConfigDisk do
  include_context "unit"

  let(:type) { :disk }

  subject { described_class.new(type) }

  let(:ui) { Vagrant::UI::Silent.new }
  let(:env) { double("env", ui: ui) }
  let(:provider) { double("provider") }
  let(:machine) { double("machine", name: "name", provider: provider, env: env,
                         provider_name: :virtualbox) }

  def assert_invalid
    errors = subject.validate(machine)
    if errors.empty?
      raise "No errors: #{errors.inspect}"
    end
  end

  def assert_valid
    errors = subject.validate(machine)
    if !errors.empty?
      raise "Errors: #{errors.inspect}"
    end
  end

  before do
    allow(provider).to receive(:capability?).with(:validate_disk_ext).and_return(true)
    allow(provider).to receive(:capability).with(:validate_disk_ext, "vdi").and_return(true)
    allow(provider).to receive(:capability?).with(:set_default_disk_ext).and_return(true)
    allow(provider).to receive(:capability).with(:set_default_disk_ext).and_return("vdi")
  end

  describe "with defaults" do
    before do
      subject.name = "foo"
      subject.size = 100
    end

    it "is valid with test defaults" do
      subject.finalize!
      assert_valid
    end

    it "sets a disk type" do
      subject.finalize!
      expect(subject.type).to eq(type)
    end

    it "defaults to non-primary disk" do
      subject.finalize!
      expect(subject.primary).to eq(false)
    end
  end

  describe "with an invalid config" do
    before do
      subject.name = "bar"
    end

    it "raises an error if size not set" do
      subject.finalize!
      assert_invalid
    end

    context "with an invalid disk extension" do
      before do
        subject.size = 100
        subject.disk_ext = "fake"

        allow(provider).to receive(:capability?).with(:validate_disk_ext).and_return(true)
        allow(provider).to receive(:capability).with(:validate_disk_ext, "fake").and_return(false)
        allow(provider).to receive(:capability?).with(:default_disk_exts).and_return(true)
        allow(provider).to receive(:capability).with(:default_disk_exts).and_return(["vdi", "vmdk"])
      end

      it "raises an error" do
        subject.finalize!
        assert_invalid
      end
    end
  end

  describe "config for dvd type" do
    let(:iso_path) { "/tmp/untitled.iso" }

    before do
      subject.type = :dvd
      subject.name = "untitled"
      allow(File).to receive(:file?).with(iso_path).and_return(true)
      subject.file = iso_path
    end

    it "is valid with test defaults" do
      subject.finalize!
      assert_valid
    end

    it "is invalid if file path is unset" do
      subject.file = nil
      subject.finalize!
      assert_invalid
    end

    it "is invalid if primary" do
      subject.primary = true
      subject.finalize!
      assert_invalid
    end
  end

  describe "#add_provider_config" do
    it "normalizes provider config" do
      test_provider_config = {provider__something: "special" }
      subject.add_provider_config(**test_provider_config)
      expect(subject.provider_config).to eq( { provider: {something: "special" }} )
    end
  end
end
