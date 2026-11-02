# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/darwin/cap/smb"

describe VagrantPlugins::HostDarwin::Cap::SMB do
  include_context "unit"

  let(:subject){ VagrantPlugins::HostDarwin::Cap::SMB }
  let(:machine){ double(:machine) }
  let(:env){ double(:env) }
  let(:options){ {} }
  let(:result){ Vagrant::Util::Subprocess::Result }

  before{ allow(subject).to receive(:machine_id).and_return("CUSTOM_ID") }

  describe ".smb_installed" do
    it "is installed if sharing binary exists" do
      expect(File).to receive(:exist?).with("/usr/sbin/sharing").and_return(true)
      expect(subject.smb_installed(nil)).to be(true)
    end

    it "is not installed if sharing binary does not exist" do
      expect(File).to receive(:exist?).with("/usr/sbin/sharing").and_return(false)
      expect(subject.smb_installed(nil)).to be(false)
    end
  end

  describe ".smb_start" do
    before{ allow(Vagrant::Util::Subprocess).to receive(:execute)
        .and_return(result.new(0, "SMB-NT", "")) }

    it "should check for NT compatible password" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("pwpolicy", "gethashtypes").
        and_return(result.new(0, "SMB-NT", ""))
      subject.smb_start(env)
    end

    it "should raise error if NT compatible password is not set" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("pwpolicy", "gethashtypes").
        and_return(result.new(0, "", ""))
      expect{ subject.smb_start(env) }.to raise_error(VagrantPlugins::SyncedFolderSMB::Errors::SMBCredentialsMissing)
    end

    it "should ignore if the command returns non-zero" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("pwpolicy", "gethashtypes").
        and_return(result.new(1, "", ""))
      subject.smb_start(env)
    end

    it "should not load smb preferences if it is already loaded" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("launchctl", "list", /preferences/).and_return(result.new(0, "", ""))
      expect(Vagrant::Util::Subprocess).not_to receive(:execute).with(/sudo/, /launchctl/, "load", "-w", /preferences/)
      subject.smb_start(env)
    end

    it "should load smb preferences if it is not already loaded" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("launchctl", "list", /preferences/).and_return(result.new(1, "", ""))
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(/sudo/, /launchctl/, "load", "-w", /preferences/).and_return(result.new(0, "", ""))
      subject.smb_start(env)
    end

    it "should raise error if load smb preferences fails" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("launchctl", "list", /preferences/).and_return(result.new(1, "", ""))
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(/sudo/, /launchctl/, "load", "-w", /preferences/).and_return(result.new(1, "", ""))
      expect{ subject.smb_start(env) }.to raise_error(VagrantPlugins::SyncedFolderSMB::Errors::SMBStartFailed)
    end

    it "should not load smbd if it is already loaded" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("launchctl", "list", /smbd/).and_return(result.new(0, "", ""))
      expect(Vagrant::Util::Subprocess).not_to receive(:execute).with(/sudo/, /launchctl/, "load", "-w", /smbd/)
      subject.smb_start(env)
    end

    it "should load smbd if it is not already loaded" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("launchctl", "list", /smbd/).and_return(result.new(1, "", ""))
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(/sudo/, /launchctl/, "load", "-w", /smbd/).and_return(result.new(0, "", ""))
      subject.smb_start(env)
    end

    it "should raise error if load smbd fails" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("launchctl", "list", /smbd/).and_return(result.new(1, "", ""))
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(/sudo/, /launchctl/, "load", "-w", /smbd/).and_return(result.new(1, "", ""))
      expect{ subject.smb_start(env) }.to raise_error(VagrantPlugins::SyncedFolderSMB::Errors::SMBStartFailed)
    end
  end

  describe ".smb_cleanup" do
    after{ subject.smb_cleanup(env, machine, options) }

    it "should search for shares with generated machine ID" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "/usr/bin/sudo", /sharing/, "-l").and_return(result.new(0, "", ""))
    end

    it "should remove shares individually" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("/usr/bin/sudo", /sharing/, "-l").
        and_return(result.new(0, "name: vgt-CUSTOM_ID-1\nname: vgt-CUSTOM_ID-2\n", ""))
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(/sudo/, /sharing/, anything, /CUSTOM_ID/).
        twice.and_return(result.new(0, "", ""))
    end
  end

  describe ".smb_prepare" do
    let(:folders){ {"/first/path" => {hostpath: "/first/host", smb_id: "ID1"},
      "/second/path" => {hostpath: "/second/host"}} }
    before{ allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(result.new(0, "", "")) }
    it "should provide ID value if not set" do
      subject.smb_prepare(env, machine, folders, options)
      expect(folders["/second/path"][:smb_id]).to start_with("vgt-")
    end

    it "should not modify ID if already set" do
      subject.smb_prepare(env, machine, folders, options)
      expect(folders["/first/path"][:smb_id]).to eq("ID1")
    end

    it "should raise error when sharing command fails" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(result.new(1, "", ""))
      expect{ subject.smb_prepare(env, machine, folders, options) }.to raise_error(
        VagrantPlugins::SyncedFolderSMB::Errors::DefineShareFailed)
    end

    it "should add shares individually" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(/sudo/, any_args).twice.and_return(result.new(0, "", ""))
      subject.smb_prepare(env, machine, folders, options)
    end
  end
end
