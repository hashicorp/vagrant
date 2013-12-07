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
    double("machine").tap do |machine|
      machine.stub(:config).and_return(machine_config)
    end
  end

  let(:machine_config) do
    double("machine_config").tap do |top_config|
      top_config.stub(:vm => vm_config)
    end
  end

  let(:vm_config) { double("machine_vm_config") }

  describe "default_synced_folder_type" do
    it "returns the usable implementation" do
      plugins = {
        "bad" => [impl(false, "bad"), 0],
        "nope" => [impl(true, "nope"), 1],
        "good" => [impl(true, "good"), 5],
      }

      result = subject.default_synced_folder_type(machine, plugins)
      result.should == "good"
    end
  end

  describe "impl_opts" do
    it "should return only relevant keys" do
      env = {
        :foo_bar => "baz",
        :bar_bar => "nope",
        :foo_baz => "bar",
      }

      result = subject.impl_opts("foo", env)
      result.length.should == 2
      result[:foo_bar].should == "baz"
      result[:foo_baz].should == "bar"
    end
  end

  describe "synced_folders" do
    let(:folders) { {} }
    let(:plugins) { {} }

    before do
      plugins[:default] = [impl(true, "default"), 10]
      plugins[:nfs] = [impl(true, "nfs"), 5]

      subject.stub(:plugins => plugins)
      vm_config.stub(:synced_folders => folders)
    end

    it "should raise exception if bad type is given" do
      folders["root"] = { type: "bad" }

      expect { subject.synced_folders(machine) }.
        to raise_error(StandardError)
    end

    it "should return the proper set of folders" do
      folders["root"] = {}
      folders["nfs"] = { type: "nfs" }

      result = subject.synced_folders(machine)
      result.length.should == 2
      result[:default].should == { "root" => folders["root"] }
      result[:nfs].should == { "nfs" => folders["nfs"] }
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
      result.length.should == 1
      result[:default].length.should == 1
    end
  end
end
