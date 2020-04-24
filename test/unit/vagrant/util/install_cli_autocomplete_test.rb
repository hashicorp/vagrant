require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/install_cli_autocomplete'
require 'fileutils'

describe Vagrant::Util::InstallZSHShellConfig do

  let(:home) { "#{Dir.tmpdir}/not-home" }
  let(:target_file) { "#{home}/.zshrc" }

  subject { described_class.new() }

  before do
    Dir.mkdir(home)
    File.open(target_file, "w") do |f|
      f.write("some content")
    end
  end

  after do
    FileUtils.rm_rf(home)
  end

  describe "#shell_installed" do
    it "should return path to config file if exists" do
      expect(subject.shell_installed(home)).to eq(target_file) 
    end

    it "should return nil if config file does not exists" do
      FileUtils.rm_rf(target_file)
      expect(subject.shell_installed(home)).to eq(nil) 
    end
  end

  describe ".is_installed" do
    it "returns false if autocompletion not already installed" do
      expect(subject.is_installed(target_file)).to eq(false)
    end

    it "returns true if autocompletion is already installed" do
      File.open(target_file, "w") do |f|
        f.write(subject.prepend_string)
      end
      expect(subject.is_installed(target_file)).to eq(true)
    end
  end

  describe ".install" do
    it "installs autocomplete" do
      subject.install(home)
      file = File.open(target_file)
      content = file.read
      expect(content.include?(subject.prepend_string)).to eq(true)
      expect(content.include?(subject.string_insert)).to eq(true)
      expect(content.include?(subject.append_string)).to eq(true)
      file.close
    end
  end
end
