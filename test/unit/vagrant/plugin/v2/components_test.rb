require File.expand_path("../../../../base", __FILE__)

require "vagrant/registry"

describe Vagrant::Plugin::V2::Components do
  subject { described_class.new }

  it "should have synced folders" do
    subject.synced_folders.should be_kind_of(Vagrant::Registry)
  end

  describe "configs" do
    it "should have configs" do
      subject.configs.should be_kind_of(Hash)
    end

    it "should default the values to registries" do
      subject.configs[:i_probably_dont_exist].should be_kind_of(Vagrant::Registry)
    end
  end
end
