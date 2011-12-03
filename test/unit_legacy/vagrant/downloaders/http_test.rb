require "test_helper"

class HttpDownloaderTest < Test::Unit::TestCase
  setup do
    @downloader, @tempfile = vagrant_mock_downloader(Vagrant::Downloaders::HTTP)
    @downloader.stubs(:report_progress)
    @downloader.stubs(:complete_progress)
    @uri = "http://google.com/"
    @headers = nil
  end

  context "downloading" do
    setup do
      ENV["http_proxy"] = nil

      @parsed_uri = URI.parse(@uri)
      @http = Net::HTTP.new(@parsed_uri.host, @parsed_uri.port)
      Net::HTTP.stubs(:new).returns(@http)
      @http.stubs(:start)
    end

    should "create a proper net/http object" do
      Net::HTTP.expects(:new).with(@parsed_uri.host, @parsed_uri.port, nil, nil, nil, nil).once.returns(@http)
      @http.expects(:start)
      @downloader.download!(@uri, @tempfile)
    end

    should "create a proper net/http object with a proxy" do
      ENV["http_proxy"] = "http://user:foo@google.com"
      @proxy = URI.parse(ENV["http_proxy"])
      Net::HTTP.expects(:new).with(@parsed_uri.host, @parsed_uri.port, @proxy.host, @proxy.port, @proxy.user, @proxy.password).once.returns(@http)
      @http.expects(:start)
      @downloader.download!(@uri, @tempfile)
    end

    should "create a proper net/http object without a proxy if no_proxy defined" do
      @uri = "http://somewhere.direct.com/some_file"
      @parsed_uri = URI.parse(@uri)
      ENV["http_proxy"] = "http://user:foo@google.com"
      ENV["no_proxy"] = "direct.com"
      Net::HTTP.expects(:new).with(@parsed_uri.host, @parsed_uri.port, nil, nil, nil, nil).once.returns(@http)
      @http.expects(:start)
      @downloader.download!(@uri, @tempfile)
    end

    should "enable SSL if scheme is https" do
      @uri = "https://google.com/"
      @http.expects(:use_ssl=).with(true).once
      @downloader.download!(@uri, @tempfile)
    end

    should "read the body of the response and place each segment into the file" do
      h = mock("http")
      response = mock("response")
      response.stubs(:content_length)
      response.stubs(:is_a?).with(anything).returns(false)
      response.stubs(:is_a?).with(Net::HTTPOK).returns(true)
      segment = mock("segment")
      segment.stubs(:length).returns(7)

      @http.stubs(:start).yields(h)
      h.expects(:request_get).with(@parsed_uri.request_uri, @headers).once.yields(response)
      response.expects(:read_body).once.yields(segment)
      @tempfile.expects(:write).with(segment).once

      @downloader.download!(@uri, @tempfile)
    end

    should "error environment if invalid URL given" do
      Net::HTTP.expects(:new).raises(SocketError.new)

      assert_raises(Vagrant::Errors::DownloaderHTTPSocketError) {
        @downloader.download!(@uri, @tempfile)
      }
    end
  end

  context "matching the uri" do
    should "use extract to verify that the string is in fact a uri" do
      URI.expects(:extract).returns(['foo'])
      assert Vagrant::Downloaders::HTTP.match?('foo')
    end

    should "return false if there are no extract results" do
      URI.expects(:extract).returns([])
      assert !Vagrant::Downloaders::HTTP.match?('foo')
    end
  end

  context "reporting progress" do
    # TODO: Testing for this, probably
  end
end
