require "pathname"
require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

require Vagrant.source_root.join("plugins/kernel_v2/config/vm")

describe Vagrant::Action::Builtin::SyncedFolders do
  include_context "unit"
  include_context "synced folder actions"

  let(:app) { lambda { |env| } }
  let(:env) { { machine: machine, ui: ui } }
  let(:machine) do
    double("machine").tap do |machine|
      allow(machine).to receive(:config).and_return(machine_config)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |top_config|
      allow(top_config).to receive(:vm).and_return(vm_config)
    end
  end

  let(:vm_config) { double("machine_vm_config") }

  let(:ui) { Vagrant::UI::Silent.new }

  subject { described_class.new(app, env) }

  describe "call" do
    let(:synced_folders) { {} }
    let(:plugins) { {} }

    before do
      plugins[:default] = [impl(true, "default"), 10]
      plugins[:nfs] = [impl(true, "nfs"), 5]

      env[:root_path] = Pathname.new(Dir.mktmpdir("vagrant-test-synced-folders-call"))
      allow(subject).to receive(:plugins).and_return(plugins)
      allow(subject).to receive(:synced_folders).and_return(synced_folders)
      allow(subject).to receive(:save_synced_folders)
      allow(machine).to receive_message_chain(:guest, :capability?).with(:persist_mount_shared_folder).and_return(false)
    end

    after do
      FileUtils.rm_rf(env[:root_path])
    end

    it "should create on the host if specified" do
      synced_folders["default"] = {
        "root" => {
          hostpath: "foo",
        },

        "other" => {
          hostpath: "bar",
          create: true,
        }
      }

      subject.call(env)

      expect(env[:root_path].join("foo")).not_to be_directory
      expect(env[:root_path].join("bar")).to be_directory
    end

    it "doesn't expand the host path if told not to" do
      called_folders = nil
      tracker = Class.new(impl(true, "good")) do
        define_method(:prepare) do |machine, folders, opts|
          called_folders = folders
        end
      end

      plugins[:tracker] = [tracker, 15]

      synced_folders["tracker"] = {
        "root" => {
          hostpath: "foo",
          hostpath_exact: true,
        },

        "other" => {
          hostpath: "/bar",
        }
      }

      subject.call(env)

      expect(called_folders).to_not be_nil
      expect(called_folders["root"][:hostpath]).to eq("foo")
    end

    it "expands the host path relative to the root path" do
      called_folders = nil
      tracker = Class.new(impl(true, "good")) do
        define_method(:prepare) do |machine, folders, opts|
          called_folders = folders
        end
      end

      plugins[:tracker] = [tracker, 15]

      synced_folders["tracker"] = {
        "root" => {
          hostpath: "foo",
        },

        "other" => {
          hostpath: "/bar",
        }
      }

      subject.call(env)

      expect(called_folders).to_not be_nil
      expect(called_folders["root"][:hostpath]).to eq(
        Pathname.new(File.expand_path(
          called_folders["root"][:hostpath],
          env[:root_path])).to_s)
    end

    it "should invoke prepare then enable" do
      ids   = []
      order = []
      tracker = Class.new(impl(true, "good")) do
        define_method(:prepare) do |machine, folders, opts|
          ids   << self.object_id
          order << :prepare
        end

        define_method(:enable) do |machine, folders, opts|
          ids   << self.object_id
          order << :enable
        end
      end

      plugins[:tracker] = [tracker, 15]

      synced_folders["tracker"] = {
        "root" => {
          hostpath: "foo",
        },

        "other" => {
          hostpath: "bar",
          create: true,
        }
      }

      subject.call(env)

      expect(order).to eq([:prepare, :enable])
      expect(ids.length).to eq(2)
      expect(ids[0]).to eq(ids[1])
    end

    it "syncs custom folders" do
      ids   = []
      order = []
      tracker = Class.new(impl(true, "good")) do
        define_method(:prepare) do |machine, folders, opts|
          ids   << self.object_id
          order << :prepare
        end

        define_method(:enable) do |machine, folders, opts|
          ids   << self.object_id
          order << :enable
        end
      end

      plugins[:tracker] = [tracker, 15]

      synced_folders["tracker"] = {
        "root" => {
          hostpath: "foo",
        },

        "other" => {
          hostpath: "bar",
          create: true,
        }
      }

      new_config = double("config")
      env[:synced_folders_config] = new_config

      expect(subject).to receive(:synced_folders).
        with(machine, config: new_config, cached: false).
        and_return(synced_folders)

      subject.call(env)

      expect(order).to eq([:prepare, :enable])
      expect(ids.length).to eq(2)
      expect(ids[0]).to eq(ids[1])
    end

    context "with folders from the machine" do
      it "removes outdated folders not present in config" do
        expect(subject).to receive(:save_synced_folders).with(
          machine, anything, merge: true, vagrantfile: true)

        subject.call(env)
      end
    end

    context "with custom folders" do
      before do
        new_config = double("config")
        env[:synced_folders_config] = new_config

        allow(subject).to receive(:synced_folders).
          with(machine, config: new_config, cached: false).
          and_return({})
      end

      it "doesn't remove outdated folders not present in config" do
        expect(subject).to receive(:save_synced_folders).with(
          machine, anything, merge: true)

        subject.call(env)
      end
    end

    context "with guest capability to persist synced folders" do
      it "persists folders" do
        synced_folders["default"] = {
          "root" => {
            hostpath: "foo",
          },

          "other" => {
            hostpath: "bar",
            create: true,
          }
        }
        allow(machine).to receive_message_chain(:guest, :capability?).with(:persist_mount_shared_folder).and_return(true)
        expect(vm_config).to receive(:allow_fstab_modification).and_return(true)
        expect(machine).to receive_message_chain(:guest, :capability).with(:persist_mount_shared_folder, synced_folders)
        subject.call(env)
      end

      it "does not persists folders if configured to not do so" do
        allow(machine).to receive_message_chain(:guest, :capability?).with(:persist_mount_shared_folder).and_return(true)
        expect(vm_config).to receive(:allow_fstab_modification).and_return(false)
        expect(machine).to receive_message_chain(:guest, :capability).with(:persist_mount_shared_folder, nil)
        subject.call(env)
      end
    end

    context "when guest is not available" do
      it "does not persist folders if guest is not available" do
      allow(machine).to receive_message_chain(:guest, :capability?).and_raise(Vagrant::Errors::MachineGuestNotReady)
      expect(vm_config).to_not receive(:allow_fstab_modification)
      subject.call(env)
      end
    end
  end
end
