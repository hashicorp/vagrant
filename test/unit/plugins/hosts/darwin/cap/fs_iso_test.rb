# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "pathname"
require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/darwin/cap/fs_iso"

describe VagrantPlugins::HostDarwin::Cap::FsISO do
  include_context "unit"

  let(:subject){ VagrantPlugins::HostDarwin::Cap::FsISO }
  let(:env) { double("env") }

  describe ".isofs_available" do
    it "finds iso building utility when available" do
      expect(Vagrant::Util::Which).to receive(:which).and_return(true)
      expect(subject.isofs_available(env)).to eq(true)
    end
  end

  describe ".create_iso" do
    let(:file_destination) { "/woo/out.iso" }

    before do 
      allow(file_destination).to receive(:nil?).and_return(false)
    end

    it "builds an iso" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-ov", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))
      expect(FileUtils).to receive(:mkdir_p).with(Pathname.new(file_destination).dirname)

      output = subject.create_iso(env, "/foo/src", file_destination: file_destination)
      expect(output.to_s).to eq("/woo/out.iso")
    end

    it "builds an iso with volume_id" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-ov", "-default-volume-name", "cidata", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))
      expect(FileUtils).to receive(:mkdir_p).with(Pathname.new(file_destination).dirname)

      output = subject.create_iso(env, "/foo/src", file_destination: file_destination, volume_id: "cidata")
      expect(output.to_s).to eq("/woo/out.iso")
    end

    it "builds an iso given a file destination without an extension" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-ov", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))
      expect(FileUtils).to receive(:mkdir_p).with(Pathname.new("/woo/out_dir"))


      output = subject.create_iso(env, "/foo/src", file_destination: "/woo/out_dir")
      expect(output.to_s).to match(/\/woo\/out_dir\/[\w]{6}_vagrant.iso/)
    end

    it "builds an iso when no file destination is given" do
      allow(Tempfile).to receive(:new).and_return(file_destination)
      allow(file_destination).to receive(:path).and_return(file_destination)
      allow(file_destination).to receive(:delete)
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-ov", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))
      # Should create a directory wherever Tempfile creates files by default
      expect(FileUtils).to receive(:mkdir_p).with(Pathname.new(file_destination).dirname)
      allow(file_destination).to receive(:close)
      allow(file_destination).to receive(:unlink)
      output = subject.create_iso(env, "/foo/src")
      expect(output.to_s).to eq(file_destination)
    end

    it "raises an error if iso build failed" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).with(any_args).and_return(double(stdout: "nope", stderr: "nope", exit_code: 1))
      expect(FileUtils).to receive(:mkdir_p).with(Pathname.new(file_destination).dirname)

      expect{ subject.create_iso(env, "/foo/src", file_destination: file_destination) }.to raise_error(Vagrant::Errors::ISOBuildFailed)
    end
  end
end
