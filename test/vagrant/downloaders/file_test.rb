require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class FileDownloaderTest < Test::Unit::TestCase
  setup do
    @downloader, @tempfile = mock_downloader(Vagrant::Downloaders::File)
    @uri = "foo.box"
  end

  context "downloading" do
    setup do
      @file = mock("file")
      @file.stubs(:read)
      @file.stubs(:eof?).returns(false)
      @downloader.stubs(:open).yields(@file)
    end

    should "open with the given uri" do
      @downloader.expects(:open).with(@uri).once
      @downloader.download!(@uri, @tempfile)
    end

    should "buffer the read from the file and write to the tempfile" do
      data = mock("data")
      write_seq = sequence("write_seq")
      @file.stubs(:eof?).returns(false).in_sequence(write_seq)
      @file.expects(:read).returns(data).in_sequence(write_seq)
      @tempfile.expects(:write).with(data).in_sequence(write_seq)
      @file.stubs(:eof?).returns(true).in_sequence(write_seq)
      @downloader.download!(@uri, @tempfile)
    end
  end
end
