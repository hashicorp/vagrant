require File.expand_path("../../../base", __FILE__)

require "vagrant/util/platform"
require "vagrant/util/ssh"

describe Vagrant::Util::SSH do
  include_context "unit"

  describe "checking key permissions" do
    let(:key_path) { temporary_file }

    it "should do nothing on Windows" do
      allow(Vagrant::Util::Platform).to receive(:windows?).and_return(true)

      key_path.chmod(0700)

      # Get the mode now and verify that it is untouched afterwards
      mode = key_path.stat.mode
      described_class.check_key_permissions(key_path)
      expect(key_path.stat.mode).to eq(mode)
    end

    it "should fix the permissions", :skip_windows do
      key_path.chmod(0644)

      described_class.check_key_permissions(key_path)
      expect(key_path.stat.mode).to eq(0100600)
    end
  end
end
