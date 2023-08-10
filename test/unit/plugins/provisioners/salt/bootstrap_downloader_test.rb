# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

require_relative "../../../base"

require Vagrant.source_root.join("plugins/provisioners/salt/bootstrap_downloader")

describe VagrantPlugins::Salt::BootstrapDownloader do
  include_context "unit"

  subject { described_class.new(:computer) }

  describe "verify_sha256" do
    let(:sha256) { "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" }
    let(:bad_sha256) { "ffffffffffffffff" }
    let(:sha256_file) { StringIO.new("#{sha256} test_script_value") }
    let(:test_script) { StringIO.new("test_script_value") }

    it "does not error if both shas match" do
      allow(subject).to receive(:download).and_return(sha256_file)
      allow(Digest::SHA256).to receive(:hexdigest).and_return(sha256)

      expect{subject.verify_sha256(test_script)}.to_not raise_error
    end

    it "raises an exception if shas don't match" do
      allow(subject).to receive(:download).and_return(sha256_file)
      allow(Digest::SHA256).to receive(:hexdigest).and_return(bad_sha256)

      expect{subject.verify_sha256(test_script)}.to raise_error(VagrantPlugins::Salt::Errors::InvalidShasumError) { |err|
        expect(err.message).to include("The bootstrap-salt script downloaded from '#{described_class::URL}' couldn't be verified.") 
        expect(err.message).to include("Expected SHA256 '#{sha256}', but computed '#{bad_sha256}'")
      }
    end

    it "raises the correct error message to a windows guest" do
      subject = described_class.new(:windows)
      allow(subject).to receive(:download).and_return(sha256_file)
      allow(Digest::SHA256).to receive(:hexdigest).and_return(bad_sha256)

      expect{subject.verify_sha256(test_script)}.to raise_error(VagrantPlugins::Salt::Errors::InvalidShasumError) { |err|
        expect(err.message).to include("The bootstrap-salt script downloaded from '#{described_class::WINDOWS_URL}' couldn't be verified.") 
      }
    end
  end
end

