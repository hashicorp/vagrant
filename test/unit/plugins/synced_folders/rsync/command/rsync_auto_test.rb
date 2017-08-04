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

  let(:synced_folders_empty) { {} }
  let(:synced_folders_dupe) { {"1234":
                               {type: "rsync",
                                exclude: false,
                                hostpath: "/Users/brian/code/vagrant-sandbox"},
                               "5678":
                               {type: "rsync",
                                exclude: false,
                                hostpath: "/Not/The/Same/Path"},
                               "0912":
                               {type: "rsync",
                                exclude: false,
                                hostpath: "/Users/brian/code/relative-dir"}}}

  let(:helper_class) { VagrantPlugins::SyncedFolderRSync::RsyncHelper }

  let(:paths) { {} }
  let(:ssh_info) {{}}

  def machine_stub(name)
    double(name).tap do |m|
      allow(m).to receive(:id).and_return("foo")
      allow(m).to receive(:reload).and_return(nil)
      allow(m).to receive(:ssh_info).and_return(ssh_info)
      allow(m).to receive(:ui).and_return(iso_env.ui)
      allow(m).to receive(:provider).and_return(double("provider"))
      allow(m).to receive(:state).and_return(double("state", id: :not_created))
      allow(m).to receive(:env).and_return(iso_env)
      allow(m).to receive(:config).and_return(double("config"))


      allow(m.ui).to receive(:error).and_return(nil)
    end
  end

  subject do
    described_class.new(argv, iso_env).tap
  end


  describe "#execute" do
    let (:machine) { machine_stub("m") }
    let (:cached_folders) { { rsync: synced_folders_dupe } }

    # NOTE: `relative-dir` is not actually a "relative dir" in this data structure
    # due to the fact that when vagrant stores synced folders, it path expands
    # them with root_dir, and when you grab those synced_folders options from
    # the machines config file, they end up being a full path rather than a
    # relative path, and so these tests reflect that.
    # For reference:
    # https://github.com/mitchellh/vagrant/blob/9c1b014536e61b332cfaa00774a87a240cce8ed9/lib/vagrant/action/builtin/synced_folders.rb#L45-L46
    let(:config_synced_folders)  { {"/vagrant":
                                   {type: "rsync",
                                    exclude: false,
                                    hostpath: "/Users/brian/code/vagrant-sandbox"},
                                  "/vagrant/other-dir":
                                   {type: "rsync",
                                    exclude: false,
                                    hostpath: "/Users/brian/code/vagrant-sandbox/other-dir"},
                                  "/vagrant/relative-dir":
                                   {type: "rsync",
                                    exclude: false,
                                    hostpath: "/Users/brian/code/relative-dir"}}}

    before do
        allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
    end

    it "does not sync folders outside of the cwd" do
      allow(machine.ui).to receive(:info)
      allow(machine.state).to receive(:id).and_return(:created)
      allow(machine.env).to receive(:cwd).
        and_return("/Users/brian/code/vagrant-sandbox")
      allow(machine.provider).to receive(:capability?).and_return(false)
      allow(machine.config).to receive(:vm).and_return(true)
      allow(machine.config.vm).to receive(:synced_folders).and_return(config_synced_folders)

      allow(subject).to receive(:synced_folders).
        with(machine, cached: true).and_return(cached_folders)
      allow(helper_class).to receive(:rsync_single).and_return(true)
      allow(Vagrant::Util::Busy).to receive(:busy).and_return(true)
      allow(Listen).to receive(:to).and_return(true)


      expect(machine.ui).to receive(:info).
        with("Not syncing /Not/The/Same/Path as it is not part of the current working directory.")
      expect(machine.ui).to receive(:info).
        with("Watching: /Users/brian/code/vagrant-sandbox")
      expect(machine.ui).to receive(:info).
        with("Watching: /Users/brian/code/relative-dir")
      expect(helper_class).to receive(:rsync_single)

      subject.execute()
    end
  end

  subject do
    described_class.new(argv, iso_env).tap do |s|
      allow(s).to receive(:synced_folders).and_return(synced_folders_empty)
    end
  end

  describe "#callback" do
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
        allow(data[:machine]).to receive(:id).and_return(nil)
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
