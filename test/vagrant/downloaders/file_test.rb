require "test_helper"

class FileDownloaderTest < Test::Unit::TestCase
  setup do
    @downloader, @tempfile = mock_downloader(Vagrant::Downloaders::File)
    @uri = "foo.box"
  end

  context "preparing" do
    should "raise an exception if the file does not exist" do
      File.expects(:file?).with(@uri).returns(false)
      @downloader.prepare(@uri)
      assert @downloader.env.error?
      assert_equal :downloader_file_doesnt_exist, @downloader.env.error.first
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

  context "matching a uri" do
    should "return true if the File exists on the file system" do
      File.expects(:exists?).with('foo').returns(true)
      assert Vagrant::Downloaders::File.match?('foo')
    end
  end
end
