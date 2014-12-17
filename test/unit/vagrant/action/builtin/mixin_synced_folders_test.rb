require "tmpdir"

require File.expand_path("../../../../base", __FILE__)

require "vagrant/action/builtin/mixin_synced_folders"

describe Vagrant::Action::Builtin::MixinSyncedFolders do
  include_context "synced folder actions"

  subject do
    Class.new do
      extend Vagrant::Action::Builtin::MixinSyncedFolders
    end
  end

  let(:machine) do
    data_dir = Pathname.new(Dir.mktmpdir)

    double("machine").tap do |machine|
      allow(machine).to receive(:config).and_return(machine_config)
      allow(machine).to receive(:data_dir).and_return(data_dir)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |top_config|
      top_config.stub(vm: vm_config)
    end
  end

  let(:vm_config) { double("machine_vm_config", :allowed_synced_folder_types => nil) }

  describe "default_synced_folder_type" do
    it "returns the usable implementation" do
      plugins = {
        "bad" => [impl(false, "bad"), 0],
        "good" => [impl(true, "good"), 1],
        "best" => [impl(true, "best"), 5],
      }

      result = subject.default_synced_folder_type(machine, plugins)
      expect(result).to eq("best")
    end

    it "filters based on allowed_synced_folder_types" do
      expect(vm_config).to receive(:allowed_synced_folder_types).and_return(["bad", "good"])
      plugins = {
        "bad" => [impl(false, "bad"), 0],
        "good" => [impl(true, "good"), 1],
        "best" => [impl(true, "best"), 5],
      }

      result = subject.default_synced_folder_type(machine, plugins)
      expect(result).to eq("good")
    end

    it "reprioritizes based on allowed_synced_folder_types" do
      plugins = {
        "bad" => [impl(false, "bad"), 0],
        "good" => [impl(true, "good"), 1],
        "same" => [impl(true, "same"), 1],
      }

      expect(vm_config).to receive(:allowed_synced_folder_types).and_return(["good", "same"])
      result = subject.default_synced_folder_type(machine, plugins)
      expect(result).to eq("good")

      expect(vm_config).to receive(:allowed_synced_folder_types).and_return(["same", "good"])
      result = subject.default_synced_folder_type(machine, plugins)
      expect(result).to eq("same")
    end
  end

  describe "impl_opts" do
    it "should return only relevant keys" do
      env = {
        foo_bar: "baz",
        bar_bar: "nope",
        foo_baz: "bar",
      }

      result = subject.impl_opts("foo", env)
      expect(result.length).to eq(2)
      expect(result[:foo_bar]).to eq("baz")
      expect(result[:foo_baz]).to eq("bar")
    end
  end

  describe "synced_folders" do
    let(:folders) { {} }
    let(:plugins) { {} }

    before do
      plugins[:default] = [impl(true, "default"), 10]
      plugins[:nfs] = [impl(true, "nfs"), 5]

      subject.stub(plugins: plugins)
      vm_config.stub(synced_folders: folders)
    end

    it "should raise exception if bad type is given" do
      folders["root"] = { type: "bad" }

      expect { subject.synced_folders(machine) }.
        to raise_error(StandardError)
    end

    it "should return the proper set of folders" do
      folders["root"] = {}
      folders["another"] = { type: "" }
      folders["foo"] = { type: "default" }
      folders["nfs"] = { type: "nfs" }

      result = subject.synced_folders(machine)
      expect(result.length).to eq(2)
      expect(result[:default]).to eq({
        "another" => folders["another"],
        "foo" => folders["foo"],
        "root" => folders["root"],
      })
      expect(result[:nfs]).to eq({ "nfs" => folders["nfs"] })
    end

    it "should return the proper set of folders of a custom config" do
      folders["root"] = {}
      folders["another"] = {}

      other_folders = { "bar" => {} }
      other = double("config")
      other.stub(synced_folders: other_folders)

      result = subject.synced_folders(machine, config: other)
      expect(result.length).to eq(1)
      expect(result[:default]).to eq({
        "bar" => other_folders["bar"],
      })
    end

    it "should error if an explicit type is unusable" do
      plugins[:unusable] = [impl(false, "bad"), 15]
      folders["root"] = { type: "unusable" }

      expect { subject.synced_folders(machine) }.
        to raise_error
    end

    it "should ignore disabled folders" do
      folders["root"] = {}
      folders["foo"] = { disabled: true }

      result = subject.synced_folders(machine)
      expect(result.length).to eq(1)
      expect(result[:default].length).to eq(1)
    end

    it "should scope hash override the settings" do
      folders["root"] = {
        hostpath: "foo",
        type: "nfs",
        nfs__foo: "bar",
      }

      result = subject.synced_folders(machine)
      expect(result[:nfs]["root"][:foo]).to eql("bar")
    end

    it "returns {} if cached read with no cache" do
      result = subject.synced_folders(machine, cached: true)
      expect(result).to eql({})
    end

    it "should be able to save and retrieve cached versions" do
      folders["root"] = {}
      folders["another"] = { type: "" }
      folders["foo"] = { type: "default" }
      folders["nfs"] = { type: "nfs" }

      result = subject.synced_folders(machine)
      subject.save_synced_folders(machine, result)

      # Clear the folders so we know its reading from cache
      old_folders = folders.dup
      folders.clear

      result = subject.synced_folders(machine, cached: true)
      expect(result.length).to eq(2)
      expect(result[:default]).to eq({
        "another" => old_folders["another"],
        "foo" => old_folders["foo"],
        "root" => old_folders["root"],
      })
      expect(result[:nfs]).to eq({ "nfs" => old_folders["nfs"] })
    end

    it "should be able to save and retrieve cached versions" do
      folders["foo"] = { type: "default" }
      result = subject.synced_folders(machine)
      subject.save_synced_folders(machine, result)

      # Clear the folders and set some more
      folders.clear
      folders["bar"] = { type: "default" }
      folders["baz"] = { type: "nfs" }
      result = subject.synced_folders(machine)
      subject.save_synced_folders(machine, result, merge: true)

      # Clear one last time
      folders.clear

      # Read them all back
      result = subject.synced_folders(machine, cached: true)
      expect(result.length).to eq(2)
      expect(result[:default]).to eq({
        "foo" => { type: "default" },
        "bar" => { type: "default" },
      })
      expect(result[:nfs]).to eq({
        "baz" => { type: "nfs" }
      })
    end
  end

  describe "#synced_folders_diff" do
    it "sees two equal " do
      one = {
        default: { "foo" => {} },
      }

      two = {
        default: { "foo" => {} },
      }

      expect(subject.synced_folders_diff(one, two)).to be_empty
    end

    it "sees modifications" do
      one = {
        default: { "foo" => {} },
      }

      two = {
        default: { "foo" => { hostpath: "foo" } },
      }

      result = subject.synced_folders_diff(one, two)
      expect(result[:modified]).to_not be_empty
    end

    it "sees adding" do
      one = {
        default: { "foo" => {} },
      }

      two = {
        default: {
          "foo" => {},
          "bar" => {},
        },
      }

      result = subject.synced_folders_diff(one, two)
      expect(result[:added]).to_not be_empty
      expect(result[:removed]).to be_empty
      expect(result[:modified]).to be_empty
    end

    it "sees removing" do
      one = {
        default: { "foo" => {} },
      }

      two = {
        default: {},
      }

      result = subject.synced_folders_diff(one, two)
      expect(result[:added]).to be_empty
      expect(result[:removed]).to_not be_empty
      expect(result[:modified]).to be_empty
    end
  end
end
