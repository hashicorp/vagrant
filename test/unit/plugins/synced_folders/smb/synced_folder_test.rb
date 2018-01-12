require_relative "../../../base"

require Vagrant.source_root.join("plugins/synced_folders/smb/synced_folder")

describe VagrantPlugins::SyncedFolderSMB::SyncedFolder do
  include_context "unit"

  let(:iso_env) do
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest){ double("guest") }
  let(:host){ double("host") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }
  let(:host_caps){ [] }
  let(:guest_caps){ [] }
  let(:folders){ {"/first/path" => {}, "/second/path" => {}} }
  let(:options){ {} }

  before do
    allow(machine.env).to receive(:host).and_return(host)
    allow(machine).to receive(:guest).and_return(guest)
    allow(machine).to receive(:ssh_info).and_return(username: 'sshuser')
    allow(guest).to receive(:name).and_return("guest_name")
    allow(host).to receive(:capability?).and_return(false)
    host_caps.each do |cap|
      allow(host).to receive(:capability?).with(cap).and_return(true)
      allow(host).to receive(:capability).with(cap, any_args).and_return(true)
    end
    allow(guest).to receive(:capability?).and_return(false)
    guest_caps.each do |cap|
      allow(guest).to receive(:capability?).with(cap).and_return(true)
      allow(guest).to receive(:capability).with(cap, any_args).and_return(true)
    end
  end

  describe ".usable?" do
    context "without supporting capabilities" do
      it "is not usable" do
        expect(subject.usable?(machine)).to be(false)
      end

      it "raises exception when raise_error enabled" do
        expect{subject.usable?(machine, true)}.to raise_error(
          VagrantPlugins::SyncedFolderSMB::Errors::SMBNotSupported)
      end
    end

    context "with smb not installed" do
      let(:host_caps){ [:smb_installed] }

      it "is not usable" do
        expect(host).to receive(:capability).with(:smb_installed).and_return(false)
        expect(subject.usable?(machine)).to be(false)
      end
    end

    context "with smb installed" do
      let(:host_caps){ [:smb_installed] }

      it "is usable" do
        expect(subject.usable?(machine)).to be(true)
      end
    end
  end

  describe ".prepare" do
    let(:host_caps){ [:smb_start, :smb_prepare] }

    context "without credentials provided" do
      before do
        expect(machine.env.ui).to receive(:ask).and_return('username')
        expect(machine.env.ui).to receive(:ask).and_return('password')
      end

      it "should prompt for credentials" do
        subject.prepare(machine, folders, options)
      end

      it "should set credential information into all folder options" do
        subject.prepare(machine, folders, options)
        expect(folders['/first/path'][:smb_username]).to eq('username')
        expect(folders['/first/path'][:smb_password]).to eq('password')
        expect(folders['/second/path'][:smb_username]).to eq('username')
        expect(folders['/second/path'][:smb_password]).to eq('password')
      end

      it "should start the SMB service if capability is available" do
        expect(host).to receive(:capability).with(:smb_start, any_args)
        subject.prepare(machine, folders, options)
      end
    end

    context "with credentials provided" do
      context "in single share entry" do
        let(:folders){ {'/first/path' => {}, '/second/path' => {smb_username: 'smbuser', smb_password: 'smbpass'}} }

        it "should not prompt for credentials" do
          expect(machine.env.ui).not_to receive(:ask)
          subject.prepare(machine, folders, options)
        end

        it "should add existing credentials to folder options without" do
          subject.prepare(machine, folders, options)
          expect(folders['/first/path'][:smb_username]).to eq('smbuser')
          expect(folders['/first/path'][:smb_password]).to eq('smbpass')
        end
      end

      context "in both entries" do
        let(:folders){ {'/first/path' => {smb_username: 'user', smb_password: 'pass'},
          '/second/path' => {smb_username: 'smbuser', smb_password: 'smbpass'}} }

        it "should not modify existing credentials" do
          subject.prepare(machine, folders, options)
          expect(folders['/first/path'][:smb_username]).to eq('user')
          expect(folders['/first/path'][:smb_password]).to eq('pass')
          expect(folders['/second/path'][:smb_username]).to eq('smbuser')
          expect(folders['/second/path'][:smb_password]).to eq('smbpass')
        end

        it "should register passwords with scrubber" do
          expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with('pass')
          expect(Vagrant::Util::CredentialScrubber).to receive(:sensitive).with('smbpass')
          subject.prepare(machine, folders, options)
        end
      end
    end
  end

  describe ".enable" do
    it "fails when guest does not support capability" do
      expect{
        subject.enable(machine, folders, options)
      }.to raise_error(Vagrant::Errors::GuestCapabilityNotFound)
    end

    context "with guest capability supported" do
      let(:guest_caps){ [:mount_smb_shared_folder, :choose_addressable_ip_addr] }
      let(:host_caps){ [:configured_ip_addresses] }

      it "should attempt to install smb on guest" do
        expect(guest).to receive(:capability?).with(:smb_install).and_return(true)
        expect(guest).to receive(:capability).with(:smb_install, any_args)
        subject.enable(machine, folders, options)
      end

      it "should request host IP addresses" do
        expect(host).to receive(:capability).with(:configured_ip_addresses)
        subject.enable(machine, folders, options)
      end

      it "should determine guest accessible address" do
        expect(guest).to receive(:capability).with(:choose_addressable_ip_addr, any_args)
        subject.enable(machine, folders, options)
      end

      it "should error if no guest accessible address is available" do
        expect(guest).to receive(:capability).with(:choose_addressable_ip_addr, any_args).and_return(nil)
        expect{ subject.enable(machine, folders, options) }.to raise_error(
          VagrantPlugins::SyncedFolderSMB::Errors::NoHostIPAddr)
      end

      it "should default owner and group to ssh username" do
        subject.enable(machine, folders, options)
        expect(folders["/first/path"][:owner]).to eq("sshuser")
        expect(folders["/first/path"][:group]).to eq("sshuser")
        expect(folders["/second/path"][:owner]).to eq("sshuser")
        expect(folders["/second/path"][:group]).to eq("sshuser")
      end

      it "should set the host address in folder options" do
        expect(guest).to receive(:capability).with(:choose_addressable_ip_addr, any_args).and_return("ADDR")
        subject.enable(machine, folders, options)
        expect(folders["/first/path"][:smb_host]).to eq("ADDR")
        expect(folders["/second/path"][:smb_host]).to eq("ADDR")
      end

      context "with smb_host option set" do
        let(:folders){ {"/first/path" => {smb_host: "ADDR"}, "/second/path" => {}} }

        it "should not update the value" do
          expect(guest).to receive(:capability).with(:choose_addressable_ip_addr, any_args).and_return("OTHER")
          subject.enable(machine, folders, options)
          expect(folders["/first/path"][:smb_host]).to eq("ADDR")
          expect(folders["/second/path"][:smb_host]).to eq("OTHER")
        end
      end

      context "with owner and group set" do
        let(:folders){ {"/first/path" => {owner: "smbowner"}, "/second/path" => {group: "smbgroup"}} }

        it "should not update set owner or group" do
          subject.enable(machine, folders, options)
          expect(folders["/first/path"][:owner]).to eq("smbowner")
          expect(folders["/first/path"][:group]).to eq("sshuser")
          expect(folders["/second/path"][:owner]).to eq("sshuser")
          expect(folders["/second/path"][:group]).to eq("smbgroup")
        end
      end
    end
  end

  describe ".cleanup" do
    context "without supporting capability" do
      it "does nothing" do
        subject.cleanup(machine, options)
      end
    end

    context "with supporting capability" do
      let(:host_caps){ [:smb_cleanup] }

      it "runs cleanup" do
        expect(host).to receive(:capability).with(:smb_cleanup, any_args)
        subject.cleanup(machine, options)
      end
    end
  end
end
