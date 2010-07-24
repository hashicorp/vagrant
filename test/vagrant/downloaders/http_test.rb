require "test_helper"

class HttpDownloaderTest < Test::Unit::TestCase
  setup do
    @downloader, @tempfile = mock_downloader(Vagrant::Downloaders::HTTP)
    @downloader.stubs(:report_progress)
    @downloader.stubs(:complete_progress)
    @uri = "http://google.com/"
  end

  context "downloading" do
    setup do
      @parsed_uri = URI.parse(@uri)
      @http = Net::HTTP.new(@parsed_uri.host, @parsed_uri.port)
      Net::HTTP.stubs(:new).returns(@http)
      @http.stubs(:start)
    end

    should "create a proper net/http object" do
      Net::HTTP.expects(:new).with(@parsed_uri.host, @parsed_uri.port).once.returns(@http)
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
      segment = mock("segment")
      segment.stubs(:length).returns(7)

      @http.stubs(:start).yields(h)
      h.expects(:request_get).with(@parsed_uri.request_uri).once.yields(response)
      response.expects(:read_body).once.yields(segment)
      @tempfile.expects(:write).with(segment).once

      @downloader.download!(@uri, @tempfile)
    end

    should "error environment if invalid URL given" do
      Net::HTTP.expects(:new).raises(SocketError.new)
      @downloader.download!(@uri, @tempfile)

      assert @downloader.env.error?
      assert_equal :box_download_http_socket_error, @downloader.env.error.first
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
