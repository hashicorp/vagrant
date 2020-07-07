require File.expand_path("../../../base", __FILE__)

require "vagrant/util/caps"

describe Vagrant::Util::Caps do
  describe "BuildISO" do

    class TestSubject
      extend Vagrant::Util::Caps::BuildISO
      BUILD_ISO_CMD = "test".freeze
    end

    let(:subject) { TestSubject }
    let(:env) { double("env") }

    describe ".isofs_available" do
      it "finds iso building utility when available" do
        expect(Vagrant::Util::Which).to receive(:which).and_return(true)
        expect(subject.isofs_available(env)).to eq(true)
      end
  
      it "does not find iso building utility when not available" do
        expect(Vagrant::Util::Which).to receive(:which).and_return(false)
        expect(subject.isofs_available(env)).to eq(false)
      end
    end

    describe ".build_iso" do
      let(:file_destination) { Pathname.new("/woo/out.iso") }

      before do 
        allow(file_destination).to receive(:exists?).and_return(false)
        allow(FileUtils).to receive(:mkdir_p)
      end

      it "should run command" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with("test", "cmd").and_return(double(exit_code: 0))
        subject.build_iso(["test", "cmd"], "/src/dir", file_destination)
      end

      it "raise an error if command fails" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with("test", "cmd").and_return(double(exit_code: 1, stdout: "oh no", stderr: "oh no"))
        expect{ subject.build_iso(["test", "cmd"], "/src/dir", file_destination) }.to raise_error(Vagrant::Errors::ISOBuildFailed)
      end
    end
  end
end