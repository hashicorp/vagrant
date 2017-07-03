require File.expand_path("../../../base", __FILE__)

require "vagrant/util/platform"

describe Vagrant::Util::Platform do
  include_context "unit"

  subject { described_class }

  describe "#cygwin?" do
    before do
      allow(subject).to receive(:platform).and_return("test")
      described_class.reset!
    end

    after do
      described_class.reset!
    end

    around do |example|
      with_temp_env(VAGRANT_DETECTED_OS: "nope", PATH: "") do
        example.run
      end
    end

    it "returns true if VAGRANT_DETECTED_OS includes cygwin" do
      with_temp_env(VAGRANT_DETECTED_OS: "cygwin") do
        expect(subject).to be_cygwin
      end
    end

    it "returns true if OSTYPE includes cygwin" do
      with_temp_env(OSTYPE: "cygwin") do
        expect(subject).to be_cygwin
      end
    end

    it "returns true if platform has cygwin" do
      allow(subject).to receive(:platform).and_return("cygwin")
      expect(subject).to be_cygwin
    end

    it "returns false if the PATH contains cygwin" do
      with_temp_env(PATH: "C:/cygwin") do
        expect(subject).to_not be_cygwin
      end
    end

    it "returns false if nothing is available" do
      expect(subject).to_not be_cygwin
    end
  end

  describe "#fs_real_path" do
    it "fixes drive letters on Windows", :windows do
      expect(described_class.fs_real_path("c:/foo").to_s).to eql("C:/foo")
    end
  end

  describe "#windows_unc_path" do
    it "correctly converts a path" do
      expect(described_class.windows_unc_path("c:/foo").to_s).to eql("\\\\?\\c:\\foo")
    end

    context "when given a UNC path" do
      let(:unc_path){ "\\\\srvname\\path" }

      it "should not modify the path" do
        expect(described_class.windows_unc_path(unc_path).to_s).to eql(unc_path)
      end
    end
  end
end
