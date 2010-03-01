require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class HttpDownloaderTest < Test::Unit::TestCase
  setup do
    @downloader, @tempfile = mock_downloader(Vagrant::Downloaders::HTTP)
    @downloader.stubs(:report_progress)
    @uri = "foo.box"
  end

  context "downloading" do
    setup do
      @parsed_uri = mock("parsed")
      URI.stubs(:parse).with(@uri).returns(@parsed_uri)
    end

    should "parse the URI and use that parsed URI for Net::HTTP" do
      URI.expects(:parse).with(@uri).returns(@parsed_uri).once
      Net::HTTP.expects(:get_response).with(@parsed_uri).once
      @downloader.download!(@uri, @tempfile)
    end

    should "read the body of the response and place each segment into the file" do
      response = mock("response")
      response.stubs(:content_length)
      segment = mock("segment")
      segment.stubs(:length).returns(7)

      Net::HTTP.stubs(:get_response).yields(response)
      response.expects(:read_body).once.yields(segment)
      @tempfile.expects(:write).with(segment).once

      @downloader.download!(@uri, @tempfile)
    end
  end

  context "reporting progress" do
    # TODO: Testing for this, probably
  end
end
