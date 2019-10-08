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

  context "when reset is enabled" do
    let(:path) { nil }
    let(:inline) { "" }
    let(:communicator) { double("communicator") }

    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :env         => {},
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => path,
        :inline      => inline,
        :binary      => false,
        :reset       => true,
        :reboot      => false,
      )
    }

    let(:vsp) {
      VagrantPlugins::Shell::Provisioner.new(machine, config)
    }

    before {
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(vsp).to receive(:provision_ssh)
    }

    it "should provision and then reset the connection" do
      expect(vsp).to receive(:provision_ssh)
      expect(communicator).to receive(:reset!)
      vsp.provision
    end

    context "when path and inline are not set" do
      let(:path) { nil }
      let(:inline) { nil }

      it "should reset the connection and not provision" do
        expect(vsp).not_to receive(:provision_ssh)
        expect(communicator).to receive(:reset!)
        vsp.provision
      end
    end
  end

  context "when reboot is enabled" do
    let(:path) { nil }
    let(:inline) { "" }
    let(:communicator) { double("communicator") }
    let(:guest) { double("guest") }

    let(:config) {
      double(
        :config,
        :args        => "doesn't matter",
        :env         => {},
        :upload_path => "arbitrary",
        :remote?     => false,
        :path        => path,
        :inline      => inline,
        :binary      => false,
        :reset       => false,
        :reboot      => true
      )
    }

    let(:vsp) {
      VagrantPlugins::Shell::Provisioner.new(machine, config)
    }

    before {
      allow(machine).to receive(:communicate).and_return(communicator)
      allow(machine).to receive(:guest).and_return(guest)
      allow(vsp).to receive(:provision_ssh)
    }

    it "should provision and then reboot the guest" do
      expect(vsp).to receive(:provision_ssh)
      expect(guest).to receive(:capability).with(:reboot)
      vsp.provision
    end

    context "when path and inline are not set" do
      let(:path) { nil }
      let(:inline) { nil }

      it "should reboot the guest and not provision" do
        expect(vsp).not_to receive(:provision_ssh)
        expect(guest).to receive(:capability).with(:reboot)
        vsp.provision
      end
    end
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
        :reset       => false,
        :reboot      => false
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
        :reset       => false,
        :reboot      => false
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
    let(:filechecksum) { double("filechecksum", checksum: checksum_value) }
    let(:checksum_value) { double("checksum_value") }

    before do
      allow(FileChecksum).to receive(:new).and_return(filechecksum)
      allow_any_instance_of(Vagrant::Util::Downloader).to receive(:execute_curl).and_return(true)
    end

    context "that does not have matching sha1 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
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
          :sha1        => 'EXPECTED_VALUE',
          :sha256      => nil,
          :sha384      => nil,
          :sha512      => nil,
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching sha256 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
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
          :sha1        => nil,
          :sha256      => 'EXPECTED_VALUE',
          :sha384      => nil,
          :sha512      => nil,
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching sha384 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
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
          :sha1        => nil,
          :sha256      => nil,
          :sha384      => 'EXPECTED_VALUE',
          :sha512      => nil,
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching sha512 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
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
          :sha1        => nil,
          :sha256      => nil,
          :sha384      => nil,
          :sha512      => 'EXPECTED_VALUE',
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end

    context "that does not have matching md5 checksum" do
      let(:checksum_value) { "INVALID_VALUE" }
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
          :sha1        => nil,
          :sha256      => nil,
          :sha384      => nil,
          :sha512      => nil,
          :reset       => false,
          :reboot      => false
        )
      }

      it "should raise an exception" do
        vsp = VagrantPlugins::Shell::Provisioner.new(machine, config)

        expect{ vsp.provision }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
      end
    end
  end
end
