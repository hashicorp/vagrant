require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DownloadBoxActionTest < Test::Unit::TestCase
  setup do
    @uri = "foo.com"
    @runner, @vm, @action = mock_action(Vagrant::Actions::Box::Download)
    @runner.stubs(:uri).returns(@uri)
    @runner.stubs(:temp_path=)
    mock_config

    Vagrant::Env.stubs(:tmp_path).returns("foo")
  end

  context "preparing" do
    setup do
      @uri = mock("uri")
      @uri.stubs(:is_a?).returns(false)
      URI.stubs(:parse).returns(@uri)
    end

    should "raise an exception if no URI type is matched" do
      @uri.stubs(:is_a?).returns(false)
      assert_raises(Vagrant::Actions::ActionException) {
        @action.prepare
      }
    end

    should "set the downloader to file if URI is generic" do
      @uri.stubs(:is_a?).with(URI::Generic).returns(true)
      @action.prepare
      assert @action.downloader.is_a?(Vagrant::Downloaders::File)
    end

    should "set the downloader to HTTP if URI is HTTP" do
      @uri.stubs(:is_a?).with(URI::HTTP).returns(true)
      @action.prepare
      assert @action.downloader.is_a?(Vagrant::Downloaders::HTTP)
    end
  end

  context "executing" do
    setup do
      @path = "foo"

      @tempfile = mock("tempfile")
      @tempfile.stubs(:path).returns(@path)

      @action.stubs(:with_tempfile).yields(@tempfile)
      @action.stubs(:download_to)
    end

    should "make a tempfile and copy the URI contents to it" do
      @action.expects(:with_tempfile).yields(@tempfile)
      @action.expects(:download_to).with(@tempfile)
      @action.execute!
    end

    should "save the tempfile path" do
      @runner.expects(:temp_path=).with(@path).once
      @action.execute!
    end
  end

  context "rescue" do
    should "call cleanup method" do
      @action.expects(:cleanup).once
      @action.rescue(nil)
    end
  end

  context "tempfile" do
    should "create a tempfile in the vagrant tmp directory" do
      Tempfile.expects(:open).with(Vagrant::Actions::Box::Download::BASENAME, Vagrant::Env.tmp_path).once
      @action.with_tempfile
    end

    should "yield the tempfile object" do
      @tempfile = mock("tempfile")
      Tempfile.expects(:open).yields(@tempfile)

      @action.with_tempfile do |otherfile|
        assert @tempfile.equal?(otherfile)
      end
    end
  end

  context "cleaning up" do
    setup do
      @temp_path = "foo"
      @runner.stubs(:temp_path).returns(@temp_path)
      File.stubs(:exist?).returns(true)
    end

    should "delete the temporary file if it exists" do
      File.expects(:unlink).with(@temp_path).once
      @action.cleanup
    end

    should "not delete anything if it doesn't exist" do
      File.stubs(:exist?).returns(false)
      File.expects(:unlink).never
      @action.cleanup
    end
  end

  context "downloading" do
    setup do
      @downloader = mock("downloader")
      @action.stubs(:downloader).returns(@downloader)
    end

    should "call download! on the download with the URI and tempfile" do
      tempfile = "foo"
      @downloader.expects(:download!).with(@runner.uri, tempfile)
      @action.download_to(tempfile)
    end
  end
end
