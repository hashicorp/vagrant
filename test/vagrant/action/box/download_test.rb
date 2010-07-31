require "test_helper"

class DownloadBoxActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Box::Download
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env["vm"] = @vm
    @env["box"] = Vagrant::Box.new(mock_environment, "foo")
    @env["box"].uri = "http://google.com"

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
  end

  context "initializing" do
    should "initialize download classes" do
      @klass.new(@app, @env)
      assert_equal [Vagrant::Downloaders::HTTP, Vagrant::Downloaders::File], @env["download.classes"]
    end
  end

  context "with an instance" do
    setup do
      @instance = @klass.new(@app, @env)
    end

    context "calling" do
      should "call the proper methods in sequence" do
        seq = sequence("seq")
        @instance.expects(:instantiate_downloader).in_sequence(seq).returns(true)
        @instance.expects(:download).in_sequence(seq)
        @app.expects(:call).with(@env).in_sequence(seq)
        @instance.call(@env)
      end

      should "halt the chain if downloader instantiation fails" do
        seq = sequence("seq")
        @env.error!(:foo)
        @instance.expects(:instantiate_downloader).in_sequence(seq).returns(false)
        @instance.expects(:download).never
        @app.expects(:call).with(@env).never
        @instance.call(@env)
      end
    end

    context "instantiating downloader" do
      should "instantiate the proper class" do
        instance = mock("instance")
        Vagrant::Downloaders::HTTP.expects(:new).with(@env).returns(instance)
        instance.expects(:prepare).with(@env["box"].uri).once
        assert @instance.instantiate_downloader
      end

      should "error environment if URI is invalid for any downloaders" do
        @env["box"].uri = "foobar"
        assert !@instance.instantiate_downloader
        assert @env.error?
        assert_equal :box_download_unknown_type, @env.error.first
      end
    end

    context "downloading" do
      setup do
        @path = "foo"

        @tempfile = mock("tempfile")
        @tempfile.stubs(:path).returns(@path)

        @instance.stubs(:with_tempfile).yields(@tempfile)
        @instance.stubs(:download_to)
      end

      should "make a tempfile and copy the URI contents to it" do
        @instance.expects(:with_tempfile).yields(@tempfile)
        @instance.expects(:download_to).with(@tempfile)
        @instance.download
      end

      should "save the tempfile path" do
        @instance.download
        assert @env.has_key?("download.temp_path")
        assert_equal @tempfile.path, @env["download.temp_path"]
        assert_equal @tempfile.path, @instance.temp_path
      end
    end

    context "tempfile" do
      should "create a tempfile in the vagrant tmp directory" do
        File.expects(:open).with { |name, bitmask|
          name =~ /#{Vagrant::Action::Box::Download::BASENAME}/ &&  name =~ /#{@env.env.tmp_path}/
        }.once
        @instance.with_tempfile
      end

      should "yield the tempfile object" do
        @tempfile = mock("tempfile")
        File.expects(:open).yields(@tempfile)

        @instance.with_tempfile do |otherfile|
          assert @tempfile.equal?(otherfile)
        end
      end
    end

    context "cleaning up" do
      setup do
        @temp_path = "foo"
        @instance.stubs(:temp_path).returns(@temp_path)
        File.stubs(:exist?).returns(true)
      end

      should "delete the temporary file if it exists" do
        File.expects(:unlink).with(@temp_path).once
        @instance.rescue(@env)
      end

      should "not delete anything if it doesn't exist" do
        File.stubs(:exist?).returns(false)
        File.expects(:unlink).never
        @instance.rescue(@env)
      end
    end

    context "downloading to" do
      setup do
        @downloader = mock("downloader")
        @instance.instance_variable_set(:@downloader, @downloader)
      end

      should "call download! on the download with the URI and tempfile" do
        tempfile = "foo"
        @downloader.expects(:download!).with(@env["box"].uri, tempfile)
        @instance.download_to(tempfile)
      end
    end
  end
end
