# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/windows/cap/smb"

describe VagrantPlugins::HostWindows::Cap::SMB do
  let(:subject){ VagrantPlugins::HostWindows::Cap::SMB }
  let(:machine){ double(:machine, env: double(:machine_env, ui: Vagrant::UI::Silent.new)) }
  let(:env){ double(:env) }
  let(:options){ {} }
  let(:result){ Vagrant::Util::Subprocess::Result }
  let(:powershell_version){ "3" }
  let(:smblist){ <<-EOF
Name        : vgt-CUSTOM_ID-1
Path        : /a/path
Description : vgt-CUSTOM_ID-1

Name        : vgt-CUSTOM_ID-2
Path        : /other/path
Description : vgt-CUSTOM_ID-2

Name        : my-share
Path        : /my/path
Description : Not Vagrant Owned

Name        : scoped-share
Scope       : *
Path        : /scoped/path
Description : Scoped Path
    EOF
  }
  let(:netsharelist){ <<-EOF

Share name        Resource     Remark
-----------------------------------------------
vgt-CUSTOM_ID-1   /a/path      vgt-CUSTOM_ID-1
vgt-CUSTOM_ID-2   /other/path  vgt-CUSTOM_ID-2
my-share          /my/path     Not Vagran...
The command completed successfully.
    EOF
  }
  let(:netshare1){ <<-EOF
Share name vgt-CUSTOM_ID-1
Path       /a/path
Remark     vgt-CUSTOM_ID-1
    EOF
  }
  let(:netshare2){ <<-EOF
Share name vgt-CUSTOM_ID-2
Path       /other/path
Remark     vgt-CUSTOM_ID-2
    EOF
  }
  let(:netshare_my){ <<-EOF
Share name my-share
Path       /my/path
Remark     Not Vagrant Owned
    EOF
  }


  before do
    allow(subject).to receive(:machine_id).and_return("CUSTOM_ID")
    allow(Vagrant::Util::PowerShell).to receive(:version).and_return(powershell_version)
    allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return("")
    allow(subject).to receive(:sleep)
  end

  describe ".smb_mount_options" do
    it "should provide smb version of at least 2" do
      result = subject.smb_mount_options(nil)
      ver = result.detect{|i| i.start_with?("vers") }.to_s.split("=", 2).last.to_s.to_i
      expect(ver).to be >= 2
    end
  end

  describe ".smb_installed" do
    context "when powershell version is greater than 2" do
      it "is valid installation" do
        expect(subject.smb_installed(nil)).to eq(true)
      end
    end

    context "when powershell version is less than 3" do
      let(:powershell_version){ "2" }

      it "is not a valid installation" do
        expect(subject.smb_installed(nil)).to eq(false)
      end
    end
  end

  describe ".smb_cleanup" do
    before do
      allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/Get-SmbShare/).
        and_return(smblist)
      allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/net share/).and_return(netsharelist)
      allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/net share vgt-CUSTOM_ID-1/).and_return(netshare1)
      allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/net share vgt-CUSTOM_ID-2/).and_return(netshare2)
      allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/net share my/).and_return(netshare_my)
      allow(Vagrant::Util::PowerShell).to receive(:execute).and_return(result.new(0, "", ""))
    end
    after{ subject.smb_cleanup(env, machine, options) }

    it "should pause after warning user" do
      expect(machine.env.ui).to receive(:warn).and_call_original
      expect(subject).to receive(:sleep)
    end

    it "should remove owned shares" do
      expect(Vagrant::Util::PowerShell).to receive(:execute) do |*args|
        expect(args).to include("vgt-CUSTOM_ID-1")
        expect(args).to include("vgt-CUSTOM_ID-2")
        result.new(0, "", "")
      end
    end

    it "should not remove owned shares" do
      expect(Vagrant::Util::PowerShell).to receive(:execute) do |*args|
        expect(args).not_to include("my-share")
        result.new(0, "", "")
      end
    end

    it "should remove all shares in single call" do
      expect(Vagrant::Util::PowerShell).to receive(:execute).with(any_args, sudo: true).once
    end

    context "when no shares are defined" do
      before do
        expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/Get-SmbShare/).
          and_return("")
      end

      it "should not attempt to remove shares" do
        expect(Vagrant::Util::PowerShell).not_to receive(:execute).with(any_args, sudo: true)
      end

      it "should not warn user" do
        expect(machine.env.ui).not_to receive(:warn)
      end
    end

    context "when Get-SmbShare is not available" do
      before do
        expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/Get-SmbShare/).and_return(nil)
      end

      it "should fetch list using net.exe" do
        expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).with(/net share/).and_return("")
      end

      it "should remove owned shares" do
        expect(Vagrant::Util::PowerShell).to receive(:execute) do |*args|
          expect(args).to include("vgt-CUSTOM_ID-1")
          expect(args).to include("vgt-CUSTOM_ID-2")
          result.new(0, "", "")
        end
      end

      it "should not remove owned shares" do
        expect(Vagrant::Util::PowerShell).to receive(:execute) do |*args|
          expect(args).not_to include("my-share")
          result.new(0, "", "")
        end
      end
    end
  end

  describe ".smb_prepare" do
    let(:folders){ {"/first/path" => {hostpath: "/host/1"}, "/second/path" => {hostpath: "/host/2", smb_id: "ID1"}} }
    let(:options){ {} }

    before{ allow(Vagrant::Util::PowerShell).to receive(:execute).and_return(result.new(0, "", "")) }

    it "should add ID when not defined" do
      subject.smb_prepare(env, machine, folders, options)
      expect(folders["/first/path"][:smb_id]).to start_with("vgt-")
    end

    it "should not modify ID when defined" do
      subject.smb_prepare(env, machine, folders, options)
      expect(folders["/second/path"][:smb_id]).to eq("ID1")
    end

    it "should pause after warning user" do
      expect(machine.env.ui).to receive(:warn).and_call_original
      expect(subject).to receive(:sleep)
      subject.smb_prepare(env, machine, folders, options)
    end

    it "should add all shares in single call" do
      expect(Vagrant::Util::PowerShell).to receive(:execute).with(any_args, sudo: true).once
      subject.smb_prepare(env, machine, folders, options)
    end

    context "when share already exists" do
      let(:shares){ {"ID1" => {"Path" => "/host/2"}} }
      before do
        allow(File).to receive(:expand_path).and_call_original
        expect(subject).to receive(:existing_shares).and_return(shares)
      end

      it "should expand paths when comparing existing to requested" do
        expect(File).to receive(:expand_path).at_least(2).with("/host/2").and_return("expanded_path")
        subject.smb_prepare(env, machine, folders, options)
      end

      context "with different path" do
        let(:shares){ {"ID1" => {"Path" => "/host/3"}} }

        it "should raise an error" do
          expect{
            subject.smb_prepare(env, machine, folders, options)
          }.to raise_error(VagrantPlugins::SyncedFolderSMB::Errors::SMBNameError)
        end
      end
    end

    context "when no shared are defined" do
      after{ subject.smb_prepare(env, machine, {}, options) }

      it "should not attempt to add shares" do
        expect(Vagrant::Util::PowerShell).not_to receive(:execute).with(any_args, sudo: true)
      end

      it "should not warn user" do
        expect(machine.env.ui).not_to receive(:warn)
      end
    end

    context "when more than 10 shares are defined" do
      let(:folders) {
        Hash[12.times.map{|i| ["/path#{i}", {hostpath: "/host#{i}"}]}]
      }

      after{ subject.smb_prepare(env, machine, folders, options) }

      it "should execute multiple powershell commands" do
        expect(Vagrant::Util::PowerShell).to receive(:execute).twice.with(any_args, sudo: true)
      end
    end
  end

  describe ".get_smbshares" do
    before { expect(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return(smblist) }

    it "should return a Hash of share information" do
      expect(subject.get_smbshares).to be_a(Hash)
    end

    it "should provide name and description for share" do
      shares = subject.get_smbshares
      expect(shares["vgt-CUSTOM_ID-1"]).to be_a(Hash)
      expect(shares["vgt-CUSTOM_ID-1"]["Path"]).to eq("/a/path")
      expect(shares["vgt-CUSTOM_ID-1"]["Description"]).to eq("vgt-CUSTOM_ID-1")
    end

    it "should properly handle share with scope information" do
      shares = subject.get_smbshares
      expect(shares["scoped-share"]).to be_a(Hash)
      expect(shares["scoped-share"]["Path"]).to eq("/scoped/path")
      expect(shares["scoped-share"]["Description"]).to eq("Scoped Path")
    end
  end
end
