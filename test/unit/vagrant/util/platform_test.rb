require File.expand_path("../../../base", __FILE__)

require "vagrant/util/platform"

describe Vagrant::Util::Platform do
  include_context "unit"


  subject { described_class }

  describe "#cygwin_path" do
    let(:path) { "C:\\msys2\\home\\vagrant" }
    let(:updated_path) { "/home/vagrant" }
    let(:subprocess_result) do
      double("subprocess_result").tap do |result|
        allow(result).to receive(:exit_code).and_return(0)
        allow(result).to receive(:stdout).and_return(updated_path)
      end
    end

    it "takes a windows path and returns a formatted path" do
      allow(Vagrant::Util::Which).to receive(:which).and_return("C:/msys2/cygpath")
      allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)

      expect(subject.cygwin_path(path)).to eq("/home/vagrant")
    end
  end

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

  describe "#msys?" do
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

    it "returns true if VAGRANT_DETECTED_OS includes msys" do
      with_temp_env(VAGRANT_DETECTED_OS: "msys") do
        expect(subject).to be_msys
      end
    end

    it "returns true if OSTYPE includes msys" do
      with_temp_env(OSTYPE: "msys") do
        expect(subject).to be_msys
      end
    end

    it "returns true if platform has msys" do
      allow(subject).to receive(:platform).and_return("msys")
      expect(subject).to be_msys
    end

    it "returns false if the PATH contains msys" do
      with_temp_env(PATH: "C:/msys") do
        expect(subject).to_not be_msys
      end
    end

    it "returns false if nothing is available" do
      expect(subject).to_not be_msys
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

  describe ".systemd?" do
    before{ allow(subject).to receive(:windows?).and_return(false) }
    after{ subject.reset! }

    context "on windows" do
      before{ expect(subject).to receive(:windows?).and_return(true) }

      it "should return false" do
        expect(subject.systemd?).to be_falsey
      end
    end

    it "should return true if systemd is in use" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double(:result, stdout: "systemd"))
      expect(subject.systemd?).to be_truthy
    end

    it "should return false if systemd is not in use" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).and_return(double(:result, stdout: "other"))
      expect(subject.systemd?).to be_falsey
    end
  end
end
