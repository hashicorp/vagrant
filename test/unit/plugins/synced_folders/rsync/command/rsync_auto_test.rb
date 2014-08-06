require_relative "../../../../base"

require Vagrant.source_root.join("plugins/synced_folders/rsync/command/rsync_auto")

describe VagrantPlugins::SyncedFolderRSync::Command::RsyncAuto do
  include_context "unit"

  let(:argv) { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:synced_folders) { {} }

  let(:helper_class) { VagrantPlugins::SyncedFolderRSync::RsyncHelper }

  subject do
    described_class.new(argv, iso_env).tap do |s|
      s.stub(synced_folders: synced_folders)
    end
  end

  describe "#callback" do
    let(:paths) { {} }
    let(:ssh_info) {{}}

    def machine_stub(name)
      double(name).tap do |m|
        m.stub(id: "foo")
        m.stub(reload: nil)
        m.stub(ssh_info: ssh_info)
        m.stub(ui: double("ui"))

        m.ui.stub(error: nil)
      end
    end

    it "syncs modified folders to the proper path" do
      paths["/foo"] = [
        { machine: machine_stub("m1"), opts: double("opts_m1") },
        { machine: machine_stub("m2"), opts: double("opts_m2") },
      ]
      paths["/bar"] = [
        { machine: machine_stub("m3"), opts: double("opts_m3") },
      ]

      paths["/foo"].each do |data|
        expect(helper_class).to receive(:rsync_single).
          with(data[:machine], data[:machine].ssh_info, data[:opts]).
          once
      end

      m = ["/foo/bar"]
      a = []
      r = []
      subject.callback(paths, m, a, r)
    end

    it "syncs added folders to the proper path" do
      paths["/foo"] = [
        { machine: machine_stub("m1"), opts: double("opts_m1") },
        { machine: machine_stub("m2"), opts: double("opts_m2") },
      ]
      paths["/bar"] = [
        { machine: machine_stub("m3"), opts: double("opts_m3") },
      ]

      paths["/foo"].each do |data|
        expect(helper_class).to receive(:rsync_single).
          with(data[:machine], data[:machine].ssh_info, data[:opts]).
          once
      end

      m = []
      a = ["/foo/bar"]
      r = []
      subject.callback(paths, m, a, r)
    end

    it "syncs removed folders to the proper path" do
      paths["/foo"] = [
        { machine: machine_stub("m1"), opts: double("opts_m1") },
        { machine: machine_stub("m2"), opts: double("opts_m2") },
      ]
      paths["/bar"] = [
        { machine: machine_stub("m3"), opts: double("opts_m3") },
      ]

      paths["/foo"].each do |data|
        expect(helper_class).to receive(:rsync_single).
          with(data[:machine], data[:machine].ssh_info, data[:opts]).
          once
      end

      m = []
      a = []
      r = ["/foo/bar"]
      subject.callback(paths, m, a, r)
    end

    it "doesn't fail if guest error occurs" do
      paths["/foo"] = [
        { machine: machine_stub("m1"), opts: double("opts_m1") },
        { machine: machine_stub("m2"), opts: double("opts_m2") },
      ]
      paths["/bar"] = [
        { machine: machine_stub("m3"), opts: double("opts_m3") },
      ]

      paths["/foo"].each do |data|
        expect(helper_class).to receive(:rsync_single).
          with(data[:machine], data[:machine].ssh_info, data[:opts]).
          and_raise(Vagrant::Errors::MachineGuestNotReady)
      end

      m = []
      a = []
      r = ["/foo/bar"]
      expect { subject.callback(paths, m, a, r) }.
        to_not raise_error
    end

    it "doesn't sync machines with no ID" do
      paths["/foo"] = [
        { machine: machine_stub("m1"), opts: double("opts_m1") },
      ]

      paths["/foo"].each do |data|
        data[:machine].stub(id: nil)
        expect(helper_class).to_not receive(:rsync_single)
      end

      m = []
      a = []
      r = ["/foo/bar"]
      expect { subject.callback(paths, m, a, r) }.
        to_not raise_error
    end
  end
end
