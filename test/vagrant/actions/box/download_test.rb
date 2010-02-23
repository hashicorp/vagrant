require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DownloadBoxActionTest < Test::Unit::TestCase
  setup do
    @uri = "foo.com"
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::Box::Download, @uri)
    mock_config

    Vagrant::Env.stubs(:tmp_path).returns("foo")
  end

  context "executing" do
    setup do
      @tempfile = mock("tempfile")
    end

    should "make a tempfile and copy the URI contents to it" do
      @action.expects(:with_tempfile).yields(@tempfile)
      @action.expects(:copy_uri_to).with(@tempfile)
      @action.execute!
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

  context "copying URI file" do
    setup do
      @tempfile = mock("tempfile")
      @tempfile.stubs(:write)

      @file = mock("file")
      @file.stubs(:read)
      @file.stubs(:eof?).returns(false)
      @action.stubs(:open).yields(@file)
    end

    should "read from the file and write to the tempfile" do
      data = mock("data")
      write_seq = sequence("write_seq")
      @file.stubs(:eof?).returns(false).in_sequence(write_seq)
      @file.expects(:read).returns(data).in_sequence(write_seq)
      @tempfile.expects(:write).with(data).in_sequence(write_seq)
      @file.stubs(:eof?).returns(true).in_sequence(write_seq)
      @action.copy_uri_to(@tempfile)
    end
  end
end
