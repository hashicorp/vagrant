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
        m.stub(ssh_info: ssh_info)
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
  end

  describe "#execute", :execute => true do
    context "with a single machine" do
      let(:machine) { iso_env.machine(iso_env.machine_names[0], iso_env.default_provider) }
      let(:synced_folders) {{}}
      let(:listen){{}}
      let(:thread){{}}

      before do
        synced_folders[:rsync] = [
          [:one, {:hostpath => "."}],
          [:two, {:hostpath => "."}]
        ]

        # stub the Listen activity
        thread = double('thread', :join => nil)
        listen = double('listen', :start => nil, :thread => thread)
        allow(Listen).to receive(:to) { listen }

        # stub the callback method, we don't care here
        subject.stub(callback: nil)
      end

      it "enables rsync plugin and exits successfully" do
        rsync_class = Class.new Vagrant::plugin("2", :synced_folder)

        # stub the rsync plugin instanciation in order to make expectations on a predefined double
        rsync_inst  = double('rsync_inst')
        rsync_class.stub(new: rsync_inst)

        # Create a plugin for the test to be unregistered at the end
        register_plugin("2") do |plugin|
          plugin.synced_folder("rsync") do
            rsync_class
          end
        end

        expect(rsync_class).to receive(:new).once
        expect(rsync_inst).to receive(:enable).with(machine, synced_folders[:rsync], {}).once

        expect(subject.execute).to eql(0)
      end
    end
  end
end
