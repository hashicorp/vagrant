require File.expand_path("../../../base", __FILE__)

require "vagrant/util/platform"

describe Vagrant::Util::Platform do
  subject { described_class }

  describe "#fs_real_path" do
    it "fixes drive letters on Windows", :windows do
      expect(described_class.fs_real_path("c:/foo").to_s).to eql("C:/foo")
    end
  end
end
