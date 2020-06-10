require 'pathname'

require_relative "../../../../base"
require_relative "../../../../../../plugins/hosts/darwin/cap/fs_iso"

describe VagrantPlugins::HostDarwin::Cap::FsISO do
  include_context "unit"

  let(:subject){ VagrantPlugins::HostDarwin::Cap::FsISO }

  let(:env){ double("env") }

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

  describe ".create_iso" do
    before do 
      allow(subject).to receive(:iso_update_required?).and_return(true)
      allow(FileUtils).to receive(:mkdir_p)
    end

    it "builds an iso" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src", "/woo/out.iso")
      expect(output.to_s).to eq("/woo/out.iso")
    end

    it "builds an iso with args" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(
        "hdiutil", "makehybrid", "-hfs", "-iso", "-joliet", "-default-volume-name", "cidata", "-o", /.iso/, /\/foo\/src/
      ).and_return(double(exit_code: 0))

      output = subject.create_iso(env, "/foo/src", "/woo/out.iso", extra_opts={"default-volume-name" => "cidata"})
      expect(output.to_s).to eq("/woo/out.iso")
    end

    it "raises an error if iso build failed" do
      allow(Vagrant::Util::Subprocess).to receive(:execute).with(any_args).and_return(double(stdout: "nope", stderr: "nope", exit_code: 1))
      expect{ subject.create_iso(env, "/foo/src", "/woo/out.iso") }.to raise_error(Vagrant::Errors::ISOBuildFailed)
    end

    it "does not build iso if no changes required" do
      allow(subject).to receive(:iso_update_required?).and_return(false)
      expect(Vagrant::Util::Subprocess).to_not receive(:execute)
      output = subject.create_iso(env, "/foo/src", "/woo/out.iso", extra_opts={"default-volume-name" => "cidata"})
      expect(output.to_s).to eq("/woo/out.iso")
    end
  end
end
