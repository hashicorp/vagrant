require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class FileDownloaderTest < Test::Unit::TestCase
  setup do
    @downloader, @tempfile = mock_downloader(Vagrant::Downloaders::File)
    @uri = "foo.box"
  end

  context "preparing" do
    should "raise an exception if the file does not exist" do
      File.expects(:file?).with(@uri).returns(false)
      assert_raises(Vagrant::Actions::ActionException) {
        @downloader.prepare(@uri)
      }
    end
  end

  context "downloading" do
    should "cp the file" do
      path = '/path'
      @tempfile.expects(:path).returns(path)
      FileUtils.expects(:cp).with(@uri, path)
      @downloader.download!(@uri, @tempfile)
    end
  end
end
