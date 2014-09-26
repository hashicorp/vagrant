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
    machine.env.stub(host: host)
    machine.stub(guest: guest)
  end

  describe "#usable?" do
    it "is usable if rsync can be found" do
      expect(Vagrant::Util::Which).to receive(:which).with("rsync").and_return(true)
      expect(subject.usable?(machine)).to be_true
    end

    it "is not usable if rsync cant be found" do
      expect(Vagrant::Util::Which).to receive(:which).with("rsync").and_return(false)
      expect(subject.usable?(machine)).to be_false
    end

    it "raises an exception if asked to" do
      expect(Vagrant::Util::Which).to receive(:which).with("rsync").and_return(false)
      expect { subject.usable?(machine, true) }.
        to raise_error(Vagrant::Errors::RSyncNotFound)
    end
  end

  describe "#enable" do
    let(:communicator_info) {{
      private_key_path: [],
    }}

    before do
      machine.stub(communicator_info: communicator_info)
      allow(guest).to receive(:capability?).with(:rsync_installed)
    end

    it "rsyncs each folder" do
      folders = [
        [:one, {}],
        [:two, {}],
      ]

      folders.each do |_, opts|
        expect(helper_class).to receive(:rsync_single).
          with(machine, communicator_info, opts).
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
