require_relative "../../../../base"

require Vagrant.source_root.join("plugins/providers/hyperv/helper")
require Vagrant.source_root.join("plugins/providers/hyperv/command/sync_auto")

describe VagrantPlugins::HyperV::Command::SyncAuto do
  include_context "unit"

  let(:argv) { [] }
  let(:iso_env) do
    # We have to create a Vagrantfile so there is a root path
    env = isolated_environment
    env.vagrantfile("")
    env.create_vagrant_env
  end

  let(:hostpath_mappings) do
    { Windows: { "/vagrant-sandbox": 'C:\Users\brian\code\vagrant-sandbox',
                 "/Not-The-Same-Path": 'C:\Not\The\Same\Path',
                 "/relative-dir": 'C:\Users\brian\code\relative-dir',
                 "/vagrant-sandbox-other-dir": 'C:\Users\brian\code\vagrant-sandbox\other-dir' },
      WSL: { "/vagrant-sandbox": "/mnt/c/Users/brian/code/vagrant-sandbox",
             "/Not-The-Same-Path": "/mnt/c/Not/The/Same/Path",
             "/relative-dir": "/mnt/c/Users/brian/code/relative-dir",
             "/vagrant-sandbox-other-dir": "/mnt/c/Users/brian/code/vagrant-sandbox/other-dir" } }
  end
  let(:synced_folders_empty) { {} }
  let(:synced_folders_dupe) do
    { "1234":
          { type: "hyperv",
            exclude: [".git/"],
            guestpath: "/vagrant-sandbox" },
      "5678":
          { type: "hyperv",
            exclude: [".git/"],
            guestpath: "/Not-The-Same-Path" },
      "0912":
          { type: "hyperv",
            exclude: [".git/"],
            guestpath: "/relative-dir"} }
  end

  let(:helper_class) { VagrantPlugins::HyperV::SyncHelper }

  let(:paths) { {} }
  let(:ssh_info) { { username: "vagrant" }}

  before do
    I18n.load_path << Vagrant.source_root.join("templates/locales/providers_hyperv.yml")
    I18n.reload!
  end

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
    let (:excludes) { { dirs: {}, files: {} } }

    let(:config_synced_folders) do
      { "/vagrant":
            { type: "hyperv",
              exclude: [".git/"],
              guestpath: "/vagrant-sandbox" },
        "/vagrant/other-dir":
            { type: "hyperv",
              exclude: [".git/"],
              guestpath: "/vagrant-sandbox-other-dir" },
        "/vagrant/relative-dir":
            { type: "hyperv",
              exclude: [".git/"],
              guestpath: "/relative-dir" } }
    end

    before do
      allow(subject).to receive(:with_target_vms) { |&block| block.call machine }
      allow(machine.ui).to receive(:info)
      allow(machine.state).to receive(:id).and_return(:created)
      allow(machine.provider).to receive(:capability?).and_return(false)
      allow(machine.config).to receive(:vm).and_return(true)
      allow(machine.config.vm).to receive(:synced_folders).and_return(config_synced_folders)
      allow(VagrantPlugins::HyperV::SyncHelper).to receive(:expand_excludes).and_return(excludes)
      allow(helper_class).to receive(:sync_single).and_return(true)
      allow(Vagrant::Util::Busy).to receive(:busy).and_return(true)
      allow(Listen).to receive(:to).and_return(true)
    end

    %i[Windows WSL].each do |host_type|
      context "in #{host_type} environment" do
        let(:host_type) { host_type }
        let(:hostpath_mapping) { hostpath_mappings[host_type] }
        let (:cached_folders) do
          { hyperv: synced_folders_dupe.dup.tap do |folders|
            folders.values.each do |folder|
              folder[:hostpath] = hostpath_mapping[folder[:guestpath].to_sym]
            end
          end }
        end

        before do
          allow(subject).to receive(:synced_folders).
            with(machine, cached: true).and_return(cached_folders)
          cached_folders[:hyperv].values.each do |folders|
            allow(VagrantPlugins::HyperV::SyncHelper).to receive(:expand_path).
              with(folders[:hostpath], machine.env.root_path).and_return(folders[:hostpath])
          end
        end

        it "syncs all configured folders" do
          expect(helper_class).to receive(:sync_single)
          subject.execute
        end

        it "watches all configured folders for changes" do
          expect(machine.ui).to receive(:info).
            with("Doing an initial sync...")
          cached_folders[:hyperv].values.each do |folder|
            expect(machine.ui).to receive(:info).with("Watching: #{folder[:hostpath]}")
          end
          subject.execute
        end
      end
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
        expect(helper_class).to receive(:sync_single).
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
        expect(helper_class).to receive(:sync_single).
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
        expect(helper_class).to receive(:sync_single).
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
        expect(helper_class).to receive(:sync_single).
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
        expect(helper_class).to_not receive(:sync_single)
      end

      m = []
      a = []
      r = ["/foo/bar"]
      expect { subject.callback(paths, m, a, r) }.
        to_not raise_error
    end

    context "on failure" do
      let(:machine) { machine_stub("m1") }
      let(:opts) { double("opts_m1") }
      let(:paths) { {"/foo" => [machine: machine, opts: opts]} }
      let(:args) { [paths, ["/foo/bar"], [], []] }

      before do
        allow_any_instance_of(Vagrant::Errors::VagrantError).
          to receive(:translate_error)
        allow(machine.ui).to receive(:error)
      end

      context "when sync command fails" do
        before do
          expect(helper_class).to receive(:sync_single).with(machine, machine.ssh_info, opts).
            and_raise(Vagrant::Errors::VagrantError)
        end

        it "should notify on error" do
          expect(machine.ui).to receive(:error)
          subject.callback(*args)
        end

        it "should not raise error" do
          expect { subject.callback(*args) }.not_to raise_error
        end
      end
    end
  end
end
