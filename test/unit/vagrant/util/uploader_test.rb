# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require File.expand_path("../../../base", __FILE__)

require "vagrant/util/uploader"

describe Vagrant::Util::Uploader do
  let(:destination) { "fake" }
  let(:file) { "my/file.box" }
  let(:curl_options) { [destination, "--request", "PUT", "--upload-file", file, "--fail", {notify: :stderr}] }

  let(:subprocess_result) do
    double("subprocess_result").tap do |result|
      allow(result).to receive(:exit_code).and_return(exit_code)
      allow(result).to receive(:stderr).and_return("")
    end
  end

  subject { described_class.new(destination, file, options) }

  before :each do
    allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)
  end

  describe "#upload!" do
    context "with a good exit status" do
      let(:options) { {} }
      let(:exit_code) { 0 }

      it "uploads the file and returns true" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result)

        expect(subject.upload!).to be
      end
    end

    context "with a bad exit status" do
      let(:options) { {} }
      let(:exit_code) { 1 }
      it "raises an exception" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result)

        expect { subject.upload! }.
          to raise_error(Vagrant::Errors::UploaderError)
      end
    end
  end
end
