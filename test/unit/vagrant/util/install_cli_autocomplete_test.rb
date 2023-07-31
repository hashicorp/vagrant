# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/install_cli_autocomplete'
require 'fileutils'

describe Vagrant::Util::InstallZSHShellConfig do

  let(:home) { "#{Dir.tmpdir}/not-home" }
  let(:target_file) { "#{home}/.zshrc" }

  subject { described_class.new() }

  describe "#shell_installed" do
    it "should return path to config file if exists" do
      allow(File).to receive(:exist?).with(target_file).and_return(true)
      expect(subject.shell_installed(home)).to eq(target_file) 
    end

    it "should return nil if config file does not exists" do
      FileUtils.rm_rf(target_file)
      expect(subject.shell_installed(home)).to eq(nil) 
    end
  end

  describe "#is_installed" do
    it "returns false if autocompletion not already installed" do
      allow(File).to receive(:foreach).with(target_file).and_yield("nothing")
      expect(subject.is_installed(target_file)).to eq(false)
    end

    it "returns true if autocompletion is already installed" do
      allow(File).to receive(:foreach).with(target_file).and_yield(subject.prepend_string)
      expect(subject.is_installed(target_file)).to eq(true)
    end
  end

  describe "#install" do
    it "installs autocomplete" do
      allow(File).to receive(:exist?).with(target_file).and_return(true)
      allow(File).to receive(:foreach).with(target_file).and_yield("nothing")
      expect(File).to receive(:open).with(target_file, "a")
      subject.install(home)
    end
  end
end

describe Vagrant::Util::InstallCLIAutocomplete do

  let(:zshrc_path) { "/path/to/.zshrc" }
  let(:bashrc_path) { "/path/to/.bash_profile" }

  subject { described_class }

  describe ".install" do
    it "installs requested shells" do
      allow_any_instance_of(Vagrant::Util::InstallZSHShellConfig).to receive(:install).and_return(zshrc_path)
      expect(subject.install(["zsh"])).to eq([zshrc_path])
    end

    it "installs all shells by default" do
      allow_any_instance_of(Vagrant::Util::InstallZSHShellConfig).to receive(:install).and_return(zshrc_path)
      allow_any_instance_of(Vagrant::Util::InstallBashShellConfig).to receive(:install).and_return(bashrc_path)
      expect(subject.install()).to eq([zshrc_path, bashrc_path])
    end

    it "does not install unsupported shells" do
      expect{ subject.install(["oops"]) }.to raise_error(ArgumentError)
    end
  end
end
