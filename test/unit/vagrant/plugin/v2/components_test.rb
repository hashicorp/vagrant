require File.expand_path("../../../../base", __FILE__)

require "vagrant/registry"

describe Vagrant::Plugin::V2::Components do
  let(:instance) { described_class.new }

  describe "configs" do
    it "should have configs" do
      instance.configs.should be_kind_of(Hash)
    end

    it "should default the values to registries" do
      instance.configs[:i_probably_dont_exist].should be_kind_of(Vagrant::Registry)
    end
  end
end
