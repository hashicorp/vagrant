require File.expand_path("../../../base", __FILE__)

require "vagrant/util/downloader"

describe Vagrant::Util::Downloader do
  let(:source) { "foo" }
  let(:destination) { "bar" }
  let(:exit_code) { 0 }
  let(:options) { {} }

  let(:subprocess_result) do
    double("subprocess_result").tap do |result|
      allow(result).to receive(:exit_code).and_return(exit_code)
      allow(result).to receive(:stderr).and_return("")
    end
  end

  subject { described_class.new(source, destination, options) }

  before :each do
    allow(Vagrant::Util::Subprocess).to receive(:execute).and_return(subprocess_result)
  end

  describe "#download!" do
    let(:curl_options) {
      ["-q", "--fail", "--location", "--max-redirs", "10",
       "--verbose", "--user-agent", described_class::USER_AGENT,
       "--output", destination, source, {}]
    }

    context "with UI" do
      let(:ui) { double("ui") }
      let(:options) { {ui: ui} }
      let(:source) { "http://example.org/vagrant.box" }
      let(:redirect) { nil }
      let(:progress_data) { "Location: #{redirect}" }

      before do
        allow(ui).to receive(:clear_line)
        allow(ui).to receive(:detail)
      end

      after do
        expect(subject).to receive(:execute_curl) do |*_, &data_proc|
          expect(data_proc).not_to be_nil
          data_proc.call(:stderr, progress_data)
        end
        subject.download!
      end

      context "with Location header at same host" do
        let(:redirect) { "http://example.org/other-vagrant.box" }

        it "should not output redirection information" do
          expect(ui).not_to receive(:detail)
        end
      end

      context "with Location header at different host" do
        let(:redirect) { "http://example.com/vagrant.box" }

        it "should output redirection information" do
          expect(ui).to receive(:detail).with(/example.com/)
        end
      end

      context "with Location header at different subdomain" do
        let(:redirect) { "http://downloads.example.org/vagrant.box" }

        it "should output redirection information" do
          expect(ui).to receive(:detail).with(/downloads.example.org/)
        end
      end

      context "with custom header including Location name" do
        let(:custom_redirect) { "http://example.com/vagrant.box" }
        let(:progress_data) { "X-Custom-Location: #{custom_redirect}" }

        it "should not output redirection information" do
          expect(ui).not_to receive(:detail)
        end

        context "with Location header at different host" do
          let(:redirect) { "http://downloads.example.com/vagrant.box" }
          let(:progress_data) { "X-Custom-Location: #{custom_redirect}\nLocation: #{redirect}" }

          it "should output redirection information" do
            expect(ui).to receive(:detail).with(/downloads.example.com/)
          end
        end
      end
    end

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
      let(:subprocess_result_416) do
        double("subprocess_result").tap do |result|
          allow(result).to receive(:exit_code).and_return(exit_code)
          allow(result).to receive(:stderr).and_return("curl: (416) The download is fine")
        end
      end

      it "continues on if a 416 was received" do
        expect(Vagrant::Util::Subprocess).to receive(:execute).
          with("curl", *curl_options).
          and_return(subprocess_result_416)

        expect(subject.download!).to be(true)
      end

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

        expect(subject.download!).to be(true)
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

        expect(subject.download!).to be(true)
      end
    end

    context "with checksum" do
      let(:checksum_expected_value){ 'MD5_CHECKSUM_VALUE' }
      let(:checksum_invalid_value){ 'INVALID_VALUE' }
      let(:digest){ double("digest") }

      before do
        allow(digest).to receive(:file).and_return(digest)
      end

      [Digest::MD5, Digest::SHA1].each do |klass|
        short_name = klass.to_s.split("::").last.downcase

        context "using #{short_name} digest" do
          subject { described_class.new(source, destination, short_name.to_sym => checksum_expected_value) }

          context "that matches expected value" do
            before do
              expect(klass).to receive(:new).and_return(digest)
              expect(digest).to receive(:hexdigest).and_return(checksum_expected_value)
            end

            it "should not raise an exception" do
              expect(subject.download!).to be(true)
            end
          end

          context "that does not match expected value" do
            before do
              expect(klass).to receive(:new).and_return(digest)
              expect(digest).to receive(:hexdigest).and_return(checksum_invalid_value)
            end

            it "should raise an exception" do
              expect{ subject.download! }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
            end
          end
        end
      end

      context "using both md5 and sha1 digests" do
        context "that both match expected values" do
          subject { described_class.new(source, destination, md5: checksum_expected_value, sha1: checksum_expected_value) }

          before do
            expect(Digest::MD5).to receive(:new).and_return(digest)
            expect(Digest::SHA1).to receive(:new).and_return(digest)
            expect(digest).to receive(:hexdigest).and_return(checksum_expected_value).exactly(2).times
          end

          it "should not raise an exception" do
            expect(subject.download!).to be(true)
          end
        end

        context "that only sha1 matches expected value" do
          subject { described_class.new(source, destination, md5: checksum_invalid_value, sha1: checksum_expected_value) }

          before do
            allow(Digest::MD5).to receive(:new).and_return(digest)
            allow(Digest::SHA1).to receive(:new).and_return(digest)
            expect(digest).to receive(:hexdigest).and_return(checksum_expected_value).at_least(:once)
          end

          it "should raise an exception" do
            expect{ subject.download! }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
          end
        end

        context "that only md5 matches expected value" do
          subject { described_class.new(source, destination, md5: checksum_expected_value, sha1: checksum_invalid_value) }

          before do
            allow(Digest::MD5).to receive(:new).and_return(digest)
            allow(Digest::SHA1).to receive(:new).and_return(digest)
            expect(digest).to receive(:hexdigest).and_return(checksum_expected_value).at_least(:once)
          end

          it "should raise an exception" do
            expect{ subject.download! }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
          end
        end

        context "that none match expected value" do
          subject { described_class.new(source, destination, md5: checksum_invalid_value, sha1: checksum_invalid_value) }

          before do
            allow(Digest::MD5).to receive(:new).and_return(digest)
            allow(Digest::SHA1).to receive(:new).and_return(digest)
            expect(digest).to receive(:hexdigest).and_return(checksum_expected_value).at_least(:once)
          end

          it "should raise an exception" do
            expect{ subject.download! }.to raise_error(Vagrant::Errors::DownloaderChecksumError)
          end
        end
      end
    end
  end

  describe "#head" do
    let(:curl_options) {
      ["-q", "--fail", "--location", "--max-redirs", "10", "--verbose", "--user-agent", described_class::USER_AGENT, source, {}]
    }

    it "returns the output" do
      allow(subprocess_result).to receive(:stdout).and_return("foo")

      options = curl_options.dup
      options.unshift("-I")

      expect(Vagrant::Util::Subprocess).to receive(:execute).
        with("curl", *options).and_return(subprocess_result)

      expect(subject.head).to eq("foo")
    end
  end

  describe "#options" do
    describe "CURL_CA_BUNDLE" do
      let(:ca_bundle){ "CUSTOM_CA_BUNDLE" }

      context "when running within the installer" do
        before do
          allow(Vagrant).to receive(:in_installer?).and_return(true)
          allow(ENV).to receive(:[]).with("CURL_CA_BUNDLE").and_return(ca_bundle)
        end

        it "should set custom CURL_CA_BUNDLE in subprocess ENV" do
          _, subprocess_opts = subject.send(:options)
          expect(subprocess_opts[:env]).not_to be_nil
          expect(subprocess_opts[:env]["CURL_CA_BUNDLE"]).to eql(ca_bundle)
        end
      end

      context "when not running within the installer" do
        before{ allow(Vagrant).to receive(:installer?).and_return(false) }

        it "should not set custom CURL_CA_BUNDLE in subprocess ENV" do
          _, subprocess_opts = subject.send(:options)
          expect(subprocess_opts[:env]).to be_nil
        end
      end
    end
  end
end
