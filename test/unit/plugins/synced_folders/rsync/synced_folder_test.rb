require_relative "../../../base"

require Vagrant.source_root.join("plugins/synced_folders/rsync/synced_folder")

describe VagrantPlugins::SyncedFolderRSync::SyncedFolder do
  include_context "unit"

  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:guest)   { double("guest") }
  let(:host)    { double("host") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  let(:helper_class) { VagrantPlugins::SyncedFolderRSync::RsyncHelper }

  before do
    allow(machine.env).to receive(:host).and_return(host)
    allow(machine).to receive(:guest).and_return(guest)
  end

  describe "#usable?" do
    it "is usable if rsync can be found" do
      expect(Vagrant::Util::Which).to receive(:which).with("rsync").and_return(true)
      expect(subject.usable?(machine)).to be(true)
    end

    it "is not usable if rsync cant be found" do
      expect(Vagrant::Util::Which).to receive(:which).with("rsync").and_return(false)
      expect(subject.usable?(machine)).to be(false)
    end

    it "raises an exception if asked to" do
      expect(Vagrant::Util::Which).to receive(:which).with("rsync").and_return(false)
      expect { subject.usable?(machine, true) }.
        to raise_error(Vagrant::Errors::RSyncNotFound)
    end
  end

  describe "#enable" do
    let(:ssh_info) {{
      private_key_path: [],
    }}

    before do
      allow(machine).to receive(:ssh_info).and_return(ssh_info)
      allow(guest).to receive(:capability?).with(:rsync_installed)
    end

    it "rsyncs each folder" do
      folders = [
        [:one, {}],
        [:two, {}],
      ]

      folders.each do |_, opts|
        expect(helper_class).to receive(:rsync_single).
          with(machine, ssh_info, opts).
          ordered
      end

      subject.enable(machine, folders, {})
    end

    it "installs rsync if capable" do
      folders = [ [:foo, {}] ]

      allow(helper_class).to receive(:rsync_single)

      allow(guest).to receive(:capability?).with(:rsync_installed).and_return(true)
      allow(guest).to receive(:capability?).with(:rsync_install).and_return(true)

      expect(guest).to receive(:capability).with(:rsync_installed).and_return(false)
      expect(guest).to receive(:capability).with(:rsync_install)

      subject.enable(machine, folders, {})
    end

    it "errors if rsync not installable" do
      folders = [ [:foo, {}] ]

      allow(helper_class).to receive(:rsync_single)

      allow(guest).to receive(:capability?).with(:rsync_installed).and_return(true)
      allow(guest).to receive(:capability?).with(:rsync_install).and_return(false)

      expect(guest).to receive(:capability).with(:rsync_installed).and_return(false)

      expect { subject.enable(machine, folders, {}) }.
        to raise_error(Vagrant::Errors::RSyncNotInstalledInGuest)
    end
  end
end
