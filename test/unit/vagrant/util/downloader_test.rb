require File.expand_path("../../../base", __FILE__)

require "vagrant/util/downloader"

describe Vagrant::Util::Downloader do
  let(:source) { "foo" }
  let(:destination) { "bar" }
  let(:exit_code) { 0 }

  let(:subprocess_result) do
    double("subprocess_result").tap do |result|
      result.stub(:exit_code => exit_code)
      result.stub(:stderr => "")
    end
  end

  subject { described_class.new(source, destination) }

  before :each do
    Vagrant::Util::Subprocess.stub(:execute).and_return(subprocess_result)
  end

  describe "#download!" do
    let(:curl_options) {
      ["--fail", "--location", "--max-redirs", "10", "--user-agent", described_class::USER_AGENT, "--output", destination, source, {}]
    }

    context "with a good exit status" do
      let(:exit_code) { 0 }

      it "downloads the file and returns true" do
        Vagrant::Util::Subprocess.should_receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result)

        subject.download!.should be
      end
    end

    context "with a bad exit status" do
      let(:exit_code) { 1 }

      it "raises an exception" do
        Vagrant::Util::Subprocess.should_receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result)

        expect { subject.download! }.
          to raise_error(Vagrant::Errors::DownloaderError)
      end
    end

    context "with a UI" do
      pending "tests for a UI"
    end
  end
end
