require File.expand_path("../../../base", __FILE__)

require 'vagrant/util/powershell'

describe Vagrant::Util::PowerShell do
  include_context "unit"
  describe ".version" do
    before do
      allow(described_class).to receive(:executable)
        .and_return("powershell")
      allow(Vagrant::Util::Subprocess).to receive(:execute)
    end

    after do
      described_class.version
      described_class.reset!
    end

    it "should execute powershell command" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with("powershell", any_args)
    end

    it "should use the default timeout" do
      expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args, hash_including(
        timeout: Vagrant::Util::PowerShell::DEFAULT_VERSION_DETECTION_TIMEOUT))
    end

    it "should use environment variable provided timeout" do
      with_temp_env("VAGRANT_POWERSHELL_VERSION_DETECTION_TIMEOUT" => "1") do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args, hash_including(
          timeout: 1))
        described_class.version
      end
    end

    it "should use default timeout when environment variable value is invalid" do
      with_temp_env("VAGRANT_POWERSHELL_VERSION_DETECTION_TIMEOUT" => "invalid value") do
        expect(Vagrant::Util::Subprocess).to receive(:execute).with(any_args, hash_including(
          timeout: Vagrant::Util::PowerShell::DEFAULT_VERSION_DETECTION_TIMEOUT))
        described_class.version
      end
    end
  end
end
