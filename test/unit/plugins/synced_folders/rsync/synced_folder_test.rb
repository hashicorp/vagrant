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

  let(:host)    { double("host") }
  let(:machine) { iso_env.machine(iso_env.machine_names[0], :dummy) }

  before do
    machine.env.stub(host: host)
  end

  describe "#usable?" do
    it "is usable if rsync can be found" do
      Vagrant::Util::Which.should_receive(:which).with("rsync").and_return(true)
      expect(subject.usable?(machine)).to be_true
    end

    it "is not usable if rsync cant be found" do
      Vagrant::Util::Which.should_receive(:which).with("rsync").and_return(false)
      expect(subject.usable?(machine)).to be_false
    end

    it "raises an exception if asked to" do
      Vagrant::Util::Which.should_receive(:which).with("rsync").and_return(false)
      expect { subject.usable?(machine, true) }.
        to raise_error(Vagrant::Errors::RSyncNotFound)
    end
  end

  describe "#enable" do
    let(:ssh_info) { Object.new }

    before do
      machine.stub(ssh_info: ssh_info)
    end

    it "rsyncs each folder" do
      folders = [
        [:one, {}],
        [:two, {}],
      ]

      folders.each do |_, opts|
        subject.should_receive(:rsync_single).
          with(ssh_info, machine.env.root_path.to_s, machine.ui, opts).
          ordered
      end

      subject.enable(machine, folders, {})
    end
  end

  describe "#rsync_single" do
    let(:result) { Vagrant::Util::Subprocess::Result.new(0, "", "") }

    let(:ssh_info) {{
      private_key_path: [],
    }}
    let(:opts)      { {} }
    let(:root_path) { "foo" }
    let(:ui)        { machine.ui }

    before do
      Vagrant::Util::Subprocess.stub(execute: result)
    end

    it "doesn't raise an error if it succeeds" do
      subject.rsync_single(ssh_info, root_path, ui, opts)
    end

    it "raises an error if the exit code is non-zero" do
      Vagrant::Util::Subprocess.stub(
        execute: Vagrant::Util::Subprocess::Result.new(1, "", ""))

      expect {subject.rsync_single(ssh_info, root_path, ui, opts) }.
        to raise_error(Vagrant::Errors::RSyncError)
    end

    it "executes within the root path" do
      Vagrant::Util::Subprocess.should_receive(:execute).with do |*args|
        expect(args.last).to be_kind_of(Hash)

        opts = args.last
        expect(opts[:workdir]).to eql(root_path)
      end

      subject.rsync_single(ssh_info, root_path, ui, opts)
    end
  end
end
