require_relative "../../../../base"

require_relative "../../../../../../plugins/hosts/windows/cap/smb"

describe VagrantPlugins::HostWindows::Cap::SMB do
  let(:subject){ VagrantPlugins::HostWindows::Cap::SMB }
  let(:machine){ double(:machine, env: double(:machine_env, ui: double(:ui))) }
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

    EOF
  }


  before do
    allow(subject).to receive(:machine_id).and_return("CUSTOM_ID")
    allow(Vagrant::Util::PowerShell).to receive(:version).and_return(powershell_version)
    allow(Vagrant::Util::PowerShell).to receive(:execute_cmd).and_return("")
    allow(machine.env.ui).to receive(:warn)
    allow(subject).to receive(:sleep)
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
      allow(Vagrant::Util::PowerShell).to receive(:execute).and_return(result.new(0, "", ""))
    end
    after{ subject.smb_cleanup(env, machine, options) }

    it "should pause after warning user" do
      expect(machine.env.ui).to receive(:warn)
      expect(subject).to receive(:sleep)
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
      expect(machine.env.ui).to receive(:warn)
      expect(subject).to receive(:sleep)
      subject.smb_prepare(env, machine, folders, options)
    end

    it "should add all shares in single call" do
      expect(Vagrant::Util::PowerShell).to receive(:execute).with(any_args, sudo: true).once
      subject.smb_prepare(env, machine, folders, options)
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
  end
end
