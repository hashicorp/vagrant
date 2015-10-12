require File.expand_path("../../../base", __FILE__)

require "vagrant/util/downloader"

describe Vagrant::Util::Downloader do
  let(:source) { "foo" }
  let(:destination) { "bar" }
  let(:exit_code) { 0 }

  let(:subprocess_result) do
    double("subprocess_result").tap do |result|
      result.stub(exit_code: exit_code)
      result.stub(stderr: "")
    end
  end

  subject { described_class.new(source, destination) }

  before :each do
    allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)
  end

  describe "#download!" do
    let(:curl_options) {
      ["-q", "--fail", "--location", "--max-redirs", "10",
       "--user-agent", described_class::USER_AGENT,
       "--output", destination, source, {}]
    }

    context "with a good exit status" do
      let(:exit_code) { 0 }

      it "downloads the file and returns true" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result)

        expect(subject.download!).to be
      end
    end

    context "with a bad exit status" do
      let(:exit_code) { 1 }

      it "raises an exception" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result)

        expect { subject.download! }.
          to raise_error(Vagrant::Errors::DownloaderError)
      end
    end

    context "with a username and password" do
      it "downloads the file with the proper flags" do
        original_source = source
        source  = "http://foo:bar@baz.com/box.box"
        subject = described_class.new(source, destination)

        i = curl_options.index(original_source)
        curl_options[i] = "http://baz.com/box.box"

        i = curl_options.index("--output")
        curl_options.insert(i, "foo:bar")
        curl_options.insert(i, "-u")

        expect(Vagrant::Util::Subprocess).to receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result)

        expect(subject.download!).to be_true
      end
    end

    context "with an urlescaped username and password" do
      it "downloads the file with unescaped credentials" do
        original_source = source
        source  = "http://fo%5Eo:b%40r@baz.com/box.box"
        subject = described_class.new(source, destination)

        i = curl_options.index(original_source)
        curl_options[i] = "http://baz.com/box.box"

        i = curl_options.index("--output")
        curl_options.insert(i, "fo^o:b@r")
        curl_options.insert(i, "-u")

        expect(Vagrant::Util::Subprocess).to receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result)

        expect(subject.download!).to be_true
      end
    end
  end

  describe "#head" do
    let(:curl_options) {
      ["-q", "--fail", "--location", "--max-redirs", "10", "--user-agent", described_class::USER_AGENT, source, {}]
    }

    it "returns the output" do
      subprocess_result.stub(stdout: "foo")

      options = curl_options.dup
      options.unshift("-I")

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("curl", *options).and_return(subprocess_result)

      expect(subject.head).to eq("foo")
    end
  end
end
