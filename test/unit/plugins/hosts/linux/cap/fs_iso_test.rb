# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "pathname"
require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/linux/cap/fs_iso"

describe VagrantPlugins::HostLinux::Cap::FsISO do
  include_context "unit"

  let(:subject){ VagrantPlugins::HostLinux::Cap::FsISO }
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
      allow(FileUtils).to receive(:mkdir_p)
    end

    it "builds an iso" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "mkisofs", "-joliet", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src", file_destination: file_destination)
      expect(output.to_s).to eq(file_destination)
    end

    it "builds an iso with volume_id" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "mkisofs", "-joliet", "-volid", "cidata", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src", file_destination: file_destination, volume_id: "cidata")
      expect(output.to_s).to eq(file_destination)
    end

    it "builds an iso given a file destination without an extension" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "mkisofs", "-joliet", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src", file_destination: "/woo/out_dir")
      expect(output.to_s).to match(/\/woo\/out_dir\/[\w]{6}_vagrant.iso/)
    end

    it "raises an error if iso build failed" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).with(any_args).and_return(double(stdout: "nope", stderr: "nope", exit_code: 1))
      expect{ subject.create_iso(env, "/foo/src", file_destination: "/woo/out.iso") }.to raise_error(Vagrant::Errors::ISOBuildFailed)
    end
  end
end
