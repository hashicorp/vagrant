# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/caps"

describe Vagrant::Util::Caps do
  describe "BuildISO" do

    class TestSubject
      extend Vagrant::Util::Caps::BuildISO
      BUILD_ISO_CMD = "test".freeze
    end

    let(:subject) { TestSubject }
    let(:env) { double("env") }

    describe ".build_iso" do
      let(:file_destination) { Pathname.new("/woo/out.iso") }

      before do 
        allow(file_destination).to receive(:exists?).and_return(false)
        allow(FileUtils).to receive(:mkdir_p)
      end

      it "should run command" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with("test", "cmd").and_return(double(exit_code: 0))
        subject.build_iso(["test", "cmd"], "/src/dir", file_destination)
      end

      it "raise an error if command fails" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with("test", "cmd").and_return(double(exit_code: 1, stdout: "oh no", stderr: "oh no"))
        expect{ subject.build_iso(["test", "cmd"], "/src/dir", file_destination) }.to raise_error(Vagrant::Errors::ISOBuildFailed)
      end
    end
  end
end
