require File.expand_path("../../../../base", __FILE__)

require "vagrant/registry"

describe Vagrant::Plugin::V2::Components do
  subject { described_class.new }

  it "should have synced folders" do
    expect(subject.synced_folders).to be_kind_of(Vagrant::Registry)
  end

  describe "configs" do
    it "should have configs" do
      expect(subject.configs).to be_kind_of(Hash)
    end

    it "should default the values to registries" do
      expect(subject.configs[:i_probably_dont_exist]).to be_kind_of(Vagrant::Registry)
    end
  end
end
