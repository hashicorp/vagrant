require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DownloadBoxActionTest < Test::Unit::TestCase
  setup do
    @uri = "foo.com"
    @runner, @vm, @action = mock_action(Vagrant::Actions::Box::Download)
    @runner.stubs(:uri).returns(@uri)
    @runner.stubs(:temp_path=)

    @runner.env.stubs(:tmp_path).returns("foo")
  end

  context "preparing" do
    setup do
      @downloader = mock("downloader")
      Vagrant::Downloaders::File.any_instance.stubs(:prepare)
      Vagrant::Downloaders::HTTP.any_instance.stubs(:prepare)
    end

    should "raise an exception if no URI type is matched" do\
      Vagrant::Downloaders::File.expects(:match?).returns(false)
      Vagrant::Downloaders::HTTP.expects(:match?).returns(false)
      assert_raises(Vagrant::Actions::ActionException) {
        @action.prepare
      }
    end

    should "call #prepare on the downloader" do
      @downloader.expects(:prepare).with(@runner.uri).once
      Vagrant::Downloaders::File.expects(:new).returns(@downloader)
      expect_file
      @action.prepare
    end

    should "set the downloader to file if the uri provided is a file" do
      expect_file
      @action.prepare
      assert @action.downloader.is_a?(Vagrant::Downloaders::File)
    end

    should "set the downloader to HTTP if the uri provided is a valid url" do
      expect_http
      @action.prepare
      assert @action.downloader.is_a?(Vagrant::Downloaders::HTTP)
    end

    def expect_file
      Vagrant::Downloaders::File.expects(:match?).returns(true)
      Vagrant::Downloaders::HTTP.expects(:match?).returns(false)
    end

    def expect_http
      Vagrant::Downloaders::File.expects(:match?).returns(false)
      Vagrant::Downloaders::HTTP.expects(:match?).returns(true)
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
      File.expects(:open).with { |name, bitmask|
        name =~ /#{Vagrant::Actions::Box::Download::BASENAME}/ &&  name =~ /#{@runner.env.tmp_path}/
      }.once
      @action.with_tempfile
    end


    should "yield the tempfile object" do
      @tempfile = mock("tempfile")
      File.expects(:open).yields(@tempfile)

      @action.with_tempfile do |otherfile|
        assert @tempfile.equal?(otherfile)
      end
    end
  end

  context "file options" do
    should "include add binary bit to options on windows platform" do
      # This constant is not defined on non-windows platforms, so define it here
      File::BINARY = 4096 unless defined?(File::BINARY)

      Mario::Platform.expects(:windows?).returns(true)
      assert_equal @action.file_options, File::CREAT|File::EXCL|File::WRONLY|File::BINARY
    end

    should "not include binary bit on other platforms" do
      Mario::Platform.expects(:windows?).returns(false)
      assert_equal @action.file_options, File::CREAT|File::EXCL|File::WRONLY
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
