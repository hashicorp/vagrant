require File.expand_path("../../../../base", __FILE__)
require Vagrant.source_root.join("plugins/provisioners/shell/provisioner")

describe "Vagrant::Shell::Provisioner" do
  include_context "unit"

  let(:env){ isolated_environment }
  let(:machine) {
    double(:machine, env: env, id: "ID").tap { |machine|
      allow(machine).to receive_message_chain(:config, :vm, :communicator).and_return(:not_winrm)
      allow(machine).to receive_message_chain(:communicate, :tap) {}
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

  context "with a script that was set to freeze the string" do
    TEST_CONSTANT_VARIABLE = <<-TEST_CONSTANT_VARIABLE.freeze
      echo test
    TEST_CONSTANT_VARIABLE

    let(:script) { TEST_CONSTANT_VARIABLE }
    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :env         => {},
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => nil,
        :inline      => script,
        :binary      => false,
      )
    }

    it "does not raise an exception" do
      vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

      RSpec::Expectations.configuration.on_potential_false_positives = :nothing
      # This test should be fine, since we are specifically looking for the
      # string 'freeze' when RuntimeError is raised
      expect {
        vsp.provision
      }.not_to raise_error(RuntimeError)
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

      let(:digest){ double("digest") }
      before do
        allow_any_instance_of(Vagrant::Util::Downloader).to receive(:execute_curl).and_return(true)
        allow(digest).to receive(:file).and_return(digest)
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

      let(:digest){ double("digest") }
      before do
        allow_any_instance_of(Vagrant::Util::Downloader).to receive(:execute_curl).and_return(true)
        allow(digest).to receive(:file).and_return(digest)
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
