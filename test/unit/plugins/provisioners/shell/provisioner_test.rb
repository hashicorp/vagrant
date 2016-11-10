require File.expand_path("../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/provisioners/shell/provisioner")

describe "Vagrant::Shell::Provisioner" do
  include_context "unit"

  let(:env){ isolated_environment }
  let(:machine) {
    double(:machine, env: env, id: "ID").tap { |machine|
      machine.stub_chain(:config, :vm, :communicator).and_return(:not_winrm)
      machine.stub_chain(:communicate, :tap) {}
    }
  }

  before do
    allow(env).to receive(:tmp_path).and_return(Pathname.new("/dev/null"))
  end

  context "with a script that contains invalid us-ascii byte sequences" do
    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :env         => {},
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => nil,
        :inline      => script_that_is_incorrectly_us_ascii_encoded,
        :binary      => false,
      )
    }

    let(:script_that_is_incorrectly_us_ascii_encoded) {
      [207].pack("c*").force_encoding("US-ASCII")
    }

    it "does not raise an exception when normalizing newlines" do
      vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

      expect {
        vsp.provision
      }.not_to raise_error
    end
  end

  context "with remote script" do

    context "that does not have matching sha1 checksum" do
      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => "arbitrary",
          :remote?     => true,
          :path        => "http://example.com/script.sh",
          :binary      => false,
          :md5         => nil,
          :sha1        => 'EXPECTED_VALUE'
        )
      }

      let(:file){ double("file") }
      let(:digest){ double("digest") }
      before do
        Vagrant::Util::Downloader.any_instance.should_receive(:execute_curl).and_return(true)
        expect(File).to receive(:open).with(%r{/dev/null/.+}, "rb").and_yield(file).once
        allow(File).to receive(:open).and_call_original
        expect(file).to receive(:read).and_return(nil)
        expect(Digest::SHA1).to receive(:new).and_return(digest)
        expect(digest).to receive(:hexdigest).and_return('INVALID_VALUE')
      end

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching md5 checksum" do
      let(:config) {
        double(
          :config,
          :args        => "doesn't matter",
          :env         => {},
          :upload_path => "arbitrary",
          :remote?     => true,
          :path        => "http://example.com/script.sh",
          :binary      => false,
          :md5         => 'EXPECTED_VALUE',
          :sha1        => nil
        )
      }

      let(:file){ double("file") }
      let(:digest){ double("digest") }
      before do
        Vagrant::Util::Downloader.any_instance.should_receive(:execute_curl).and_return(true)
        expect(File).to receive(:open).with(%r{/dev/null/.+}, "rb").and_yield(file).once
        allow(File).to receive(:open).and_call_original
        expect(file).to receive(:read).and_return(nil)
        expect(Digest::MD5).to receive(:new).and_return(digest)
        expect(digest).to receive(:hexdigest).and_return('INVALID_VALUE')
      end

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end
  end
end
