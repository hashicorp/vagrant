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
      top_config.stub(vm: vm_config)
    end
  end

  let(:vm_config) { double("machine_vm_config") }

  let(:ui) do
    double("ui").tap do |result|
      allow(result).to receive(:info)
    end
  end

  subject { described_class.new(app, env) }

  describe "call" do
    let(:synced_folders) { {} }
    let(:plugins) { {} }

    before do
      plugins[:default] = [impl(true, "default"), 10]
      plugins[:nfs] = [impl(true, "nfs"), 5]

      env[:root_path] = Pathname.new(Dir.mktmpdir)
      subject.stub(plugins: plugins)
      subject.stub(synced_folders: synced_folders)
      allow(subject).to receive(:save_synced_folders)
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
  end
end
