require "test_helper"

class UnpackageBoxActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Box::Unpackage
    @app, @env = action_env
    @env["box"] = Vagrant::Box.new(vagrant_env, "foo")

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "call the proper chain" do
      seq = sequence("sequence")
      @instance.expects(:setup_box_directory).in_sequence(seq).returns(true)
      @instance.expects(:decompress).in_sequence(seq)
      @app.expects(:call).with(@env)
      @instance.call(@env)
    end
  end

  context "cleaning up" do
    setup do
      @instance.stubs(:box_directory).returns("foo")
      File.stubs(:directory?).returns(false)
      FileUtils.stubs(:rm_rf)
    end

    should "do nothing if box directory is not set" do
      @instance.stubs(:box_directory).returns(nil)
      File.expects(:directory?).never
      FileUtils.expects(:rm_rf).never
      @instance.recover(nil)
    end

    should "do nothing if not a directory" do
      FileUtils.expects(:rm_rf).never
      @instance.recover(nil)
    end

    should "remove the directory if exists" do
      File.expects(:directory?).with(@instance.box_directory).once.returns(true)
      FileUtils.expects(:rm_rf).with(@instance.box_directory).once
      @instance.recover(nil)
    end
  end

  context "setting up the box directory" do
    setup do
      File.stubs(:directory?).returns(false)
      FileUtils.stubs(:mkdir_p)
    end

    should "error the environment if the box already exists" do
      File.expects(:directory?).returns(true)
      assert_raises(Vagrant::Errors::BoxAlreadyExists) {
        @instance.setup_box_directory
      }
    end

    should "create the directory" do
      FileUtils.expects(:mkdir_p).with(@env["box"].directory).once
      @instance.setup_box_directory
    end
  end

  context "decompressing" do
    setup do
      @env["download.temp_path"] = "bar"

      Dir.stubs(:chdir).yields
    end

    should "change to the box directory" do
      Dir.expects(:chdir).with(@env["box"].directory)
      @instance.decompress
    end

    should "open the tar file within the new directory, and extract it all" do
      Archive::Tar::Minitar.expects(:unpack).with(@env["download.temp_path"], @env["box"].directory.to_s).once
      @instance.decompress
    end
  end
end
