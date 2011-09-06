require "test_helper"

class FileDownloaderTest < Test::Unit::TestCase
  setup do
    @downloader, @tempfile = vagrant_mock_downloader(Vagrant::Downloaders::File)
    @uri = "foo.box"
  end

  context "preparing" do
    should "raise an exception if the file does not exist" do
      File.expects(:file?).with(@uri).returns(false)

      assert_raises(Vagrant::Errors::DownloaderFileDoesntExist) {
        @downloader.prepare(@uri)
      }
    end
  end

  context "downloading" do
    setup do
      clean_paths
    end

    should "cp the file" do
      uri = tmp_path.join("foo_source")
      dest = tmp_path.join("foo_dest")

      # Create the source file, then "download" it
      File.open(uri, "w+") { |f| f.write("FOO") }
      File.open(dest, "w+") do |dest_file|
        @downloader.download!(uri, dest_file)
      end

      # Finally, verify the destination file was properly created
      assert File.file?(dest)
      File.open(dest) do |f|
        assert_equal "FOO", f.read
      end
    end
  end

  context "matching a uri" do
    should "return true if the File exists on the file system" do
      File.expects(:exists?).with('foo').returns(true)
      assert Vagrant::Downloaders::File.match?('foo')
    end
  end
end
