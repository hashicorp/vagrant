# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../../base", __FILE__)

describe Vagrant::Action::General::Package do

  let(:app) { double("app", call: nil) }
  let(:env) {
    {env: environment,
      machine: machine, ui: ui}
  }
  let(:environment) { double("environment") }
  let(:machine) { double("machine") }
  let(:ui) { Vagrant::UI::Silent.new }

  let(:subject) { described_class.new(app, env) }

  before do
    allow_any_instance_of(Vagrant::Errors::VagrantError).
      to receive(:translate_error)
  end

  describe ".validate!" do
    let(:output) { double("output", to_s: "output-path") }
    let(:directory) { double("directory") }

    before do
      allow(described_class).to receive(:fullpath).and_return(output)
      allow(File).to receive(:directory?).with(output).and_return(false)
      allow(File).to receive(:directory?).with(directory).and_return(true)
      allow(File).to receive(:exist?).and_return(false)
      allow(Vagrant::Util::Presence).to receive(:present?).with(directory).and_return(true)
    end

    it "should not raise an error when options are valid" do
      expect { described_class.validate!(output, directory) }.not_to raise_error
    end

    it "should raise error when output directory exists" do
      expect(File).to receive(:directory?).with(output).and_return(true)
      expect {
        described_class.validate!(output, directory)
      }.to raise_error(Vagrant::Errors::PackageOutputDirectory)
    end

    it "should raise error if output path exists" do
      expect(File).to receive(:exist?).with(output).and_return(true)
      expect {
        described_class.validate!(output, directory)
      }.to raise_error(Vagrant::Errors::PackageOutputExists)
    end

    it "should raise error if directory value not provided" do
      expect(Vagrant::Util::Presence).to receive(:present?).and_call_original
      expect {
        described_class.validate!(output, nil)
      }.to raise_error(Vagrant::Errors::PackageRequiresDirectory)
    end

    it "should raise error if directory path is not a directory" do
      expect(File).to receive(:directory?).with(directory).and_return(false)
      expect {
        described_class.validate!(output, directory)
      }.to raise_error(Vagrant::Errors::PackageRequiresDirectory)
    end
  end

  describe "#package_with_folder_path" do
    let(:expanded_path) { double("expanded_path") }

    before do
      allow(File).to receive(:expand_path).and_return(expanded_path)
    end

    it "should create box folder if it does not exist" do
      expect(File).to receive(:directory?).with(expanded_path).and_return(false)
      expect(subject).to receive(:create_box_folder).with(expanded_path)
      subject.package_with_folder_path
    end

    it "should not create box folder if it already exists" do
      expect(File).to receive(:directory?).with(expanded_path).and_return(true)
      expect(subject).not_to receive(:create_box_folder)
      subject.package_with_folder_path
    end
  end

  describe "#create_box_folder" do
    let(:path) { double("path") }

    before do
      allow(FileUtils).to receive(:mkdir_p)
      subject.instance_variable_set(:@env, env)
    end

    it "should notify user of new directory creation" do
      expect(I18n).to receive(:t).with(an_instance_of(String), hash_including(folder_path: path))
      subject.create_box_folder(path)
    end

    it "should create the directory" do
      expect(FileUtils).to receive(:mkdir_p).with(path)
      subject.create_box_folder(path)
    end
  end

  describe "#recover" do
    let(:env) { {"vagrant.error" => error} }
    let(:error) { nil }
    let(:fullpath) { double("fullpath") }

    before { allow(described_class).to receive(:fullpath).and_return(fullpath) }

    it "should delete packaged files if they exist" do
      expect(File).to receive(:exist?).with(fullpath).and_return(true)
      expect(File).to receive(:delete).with(fullpath)
      subject.recover(env)
    end

    it "should not delete anything if package files do not exist" do
      expect(File).to receive(:exist?).with(fullpath).and_return(false)
      expect(File).not_to receive(:delete).with(fullpath)
      subject.recover(env)
    end

    context "when vagrant error is PackageOutputDirectory" do
      let(:error) { Vagrant::Errors::PackageOutputDirectory.new }

      it "should not do anything" do
        expect(File).not_to receive(:exist?)
        expect(File).not_to receive(:delete)
        subject.recover(env)
      end
    end

    context "when vagrant error is PackageOutputExists" do
      let(:error) { Vagrant::Errors::PackageOutputExists.new }

      it "should not do anything" do
        expect(File).not_to receive(:exist?)
        expect(File).not_to receive(:delete)
        subject.recover(env)
      end
    end
  end

  describe "#copy_include_files" do
    let(:package_directory) { @package_directory }
    let(:package_files) {
      Dir.glob(File.join(@package_files_directory, "*")).map {|i|
        [i, File.basename(i)]
      }
    }

    before do
      @package_directory = Dir.mktmpdir
      @package_files_directory = Dir.mktmpdir
      3.times { |i| FileUtils.touch(File.join(@package_files_directory, "file.#{i}")) }
      env["package.files"] = package_files
      env["package.directory"] = package_directory
      subject.instance_variable_set(:@env, env)
    end

    after do
      FileUtils.rm_rf(@package_directory)
      FileUtils.rm_rf(@package_files_directory)
    end

    it "should copy all files to package directory" do
      subject.copy_include_files
      expected_files = package_files.map(&:last).map { |f|
        File.join(package_directory, "include", f)
      }.sort
      expect(
        Dir.glob(File.join(package_directory, "**", "*.*")).sort
      ).to eq(expected_files)
    end

    it "should notify user of copy" do
      expect(ui).to receive(:info).at_least(1).and_call_original
      subject.copy_include_files
    end
  end

  describe "#copy_info" do
    let(:package_directory) { @package_directory }
    let(:package_info) { File.join(@package_info_directory, "info.json") }

    before do
      @package_directory = Dir.mktmpdir
      @package_info_directory = Dir.mktmpdir
      FileUtils.touch(File.join(@package_info_directory, "info.json"))
      env["package.info"] = package_info
      env["package.directory"] = package_directory
      subject.instance_variable_set(:@env, env)

      allow(ui).to receive(:info)
    end

    after do
      FileUtils.rm_rf(@package_directory)
      FileUtils.rm_rf(@package_info_directory)
    end

    it "should copy the specified info.json to package directory" do
      subject.copy_info
      expected_info = File.join(package_directory, "info.json")

      expect(File.file? expected_info).to be_truthy
    end
  end

  describe "#compress" do
    let(:package_directory) { @package_directory }
    let(:fullpath) { "PATH" }

    before do
      @package_directory = Dir.mktmpdir
      FileUtils.touch(File.join(@package_directory, "test-file1"))
      env["package.directory"] = package_directory
      subject.instance_variable_set(:@env, env)

      allow(subject).to receive(:fullpath).and_return(fullpath)
    end

    after do
      FileUtils.rm_rf(package_directory)
    end

    it "should change directory into package directory" do
      expect(Vagrant::Util::SafeChdir).to receive(:safe_chdir).with(package_directory)
      subject.compress
    end

    it "should compress files using bsdtar" do
      expect(Vagrant::Util::SafeChdir).to receive(:safe_chdir).with(package_directory).and_call_original
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("bsdtar", any_args, "./test-file1")
      subject.compress
    end
  end

  describe "#write_metadata_json" do
    let(:metadata_path) { File.join(package_directory, "metadata.json") }
    let(:package_directory) { @package_directory }
    let(:machine_provider) { "machine-provider" }
    let(:default_provider) { "default-provider" }

    before do
      @package_directory = Dir.mktmpdir
      env["package.directory"] = @package_directory
      subject.instance_variable_set(:@env, env)

      allow(machine).to receive(:provider_name).and_return(machine_provider)
      allow(environment).to receive(:default_provider).and_return(default_provider)
    end

    after { FileUtils.rm_rf(@package_directory) }

    it "should not create a metadata.json file if it already exists" do
      expect(File).to receive(:exist?).with(metadata_path).and_return(true)
      expect(File).not_to receive(:write)
      subject.write_metadata_json
    end

    it "should write a metadata file" do
      expect(File).to receive(:write).with(metadata_path, any_args)
      subject.write_metadata_json
    end

    it "should write machine provider to metadata file" do
      subject.write_metadata_json
      content = JSON.load(File.read(metadata_path))
      expect(content["provider"]).to eq(machine_provider)
    end

    context "when machine provider is unset" do
      let(:machine_provider) { nil }

      it "should write default provider to metadata file" do
        subject.write_metadata_json
        content = JSON.load(File.read(metadata_path))
        expect(content["provider"]).to eq(default_provider)
      end
    end

    context "when machine provider and default provider are unset" do
      let(:machine_provider) { nil }
      let(:default_provider) { nil }

      it "should not write metadata file" do
        subject.write_metadata_json
        expect(File.exist?(metadata_path)).to be_falsey
      end
    end
  end

  describe "#setup_private_key" do
    let(:package_directory) { @package_directory }
    let(:private_key_path) { File.join(package_directory, "datadir", "private_key") }
    let(:new_key_path) { File.join(package_directory, "vagrant_private_key") }
    let(:vagrantfile_path) { File.join(package_directory, "Vagrantfile") }
    let(:data_dir) { Pathname.new(File.join(package_directory, "datadir")) }
    let(:config) {
      double("config", ssh: double("ssh", private_key_path: [private_key_path]))
    }

    before do
      @package_directory = Dir.mktmpdir
      env["package.directory"] = @package_directory
      FileUtils.mkdir(File.join(@package_directory, "datadir"))
      File.write(private_key_path, "SSH KEY")
      subject.instance_variable_set(:@env, env)

      allow(machine).to receive(:data_dir).and_return(data_dir)
      allow(machine).to receive(:config).and_return(config)
    end

    after { FileUtils.rm_rf(@package_directory) }

    it "should create a new Vagrantfile" do
      subject.setup_private_key
      expect(File.exist?(vagrantfile_path)).to be_truthy
    end

    it "should create the new private ssh key" do
      subject.setup_private_key
      expect(File.exist?(new_key_path)).to be_truthy
    end

    it "should copy the contents of the ssh key" do
      subject.setup_private_key
      expect(File.read(new_key_path)).to eq(File.read(private_key_path))
    end

    context "with no machine provided" do
      before { env.delete(:machine) }

      it "should not create a private ssh key file" do
        subject.setup_private_key
        expect(File.exist?(new_key_path)).to be_falsey
      end
    end

    context "when vagrant_private_key exists" do
      let(:private_key_path) { File.join(package_directory, "datadir", "vagrant_private_key") }

      it "should create the new private ssh key" do
        subject.setup_private_key
        expect(File.exist?(new_key_path)).to be_truthy
      end

      it "should copy the contents of the ssh key" do
        subject.setup_private_key
        expect(File.read(new_key_path)).to eq(File.read(private_key_path))
      end
    end
  end

  describe "#call" do
    let(:fullpath) { "FULLPATH" }

    before do
      allow(described_class).to receive(:validate!)
      allow(subject).to receive(:fullpath).and_return(fullpath)
      allow(subject).to receive(:package_with_folder_path)
      allow(subject).to receive(:copy_include_files)
      allow(subject).to receive(:setup_private_key)
      allow(subject).to receive(:write_metadata_json)
      allow(subject).to receive(:compress)
    end

    it "should validate required arguments" do
      expect(described_class).to receive(:validate!)
      subject.call(env)
    end

    it "should raise error if output path is a directory" do
      expect(File).to receive(:directory?).with(fullpath).and_return(true)
      expect {
        subject.call(env)
      }.to raise_error(Vagrant::Errors::PackageOutputDirectory)
    end

    it "should call the next middleware" do
      expect(app).to receive(:call)
      subject.call(env)
    end

    it "should notify of package compressing" do
      expect(ui).to receive(:info).and_call_original
      subject.call(env)
    end

    it "should copy include files" do
      expect(subject).to receive(:copy_include_files)
      subject.call(env)
    end

    it "should setup private ssh key" do
      expect(subject).to receive(:setup_private_key)
      subject.call(env)
    end

    it "should write metadata json file" do
      expect(subject).to receive(:write_metadata_json)
      subject.call(env)
    end

    it "should compress the box" do
      expect(subject).to receive(:compress)
      subject.call(env)
    end
  end
end
