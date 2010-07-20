require "test_helper"

class UnpackageBoxActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::Box::Unpackage
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env["vm"] = @vm
    @env["box"] = Vagrant::Box.new(mock_environment, "foo")

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "call the proper chain" do
      seq = sequence("sequence")
      @instance.expects(:setup_box_directory).in_sequence(seq).returns(true)
      @instance.expects(:decompress).in_sequence(seq)
      @app.expects(:call).with(@env)
      @instance.expects(:cleanup).never
      @instance.call(@env)
    end

    should "halt the chain if setting up the box directory fails" do
      @instance.expects(:setup_box_directory).returns(false)
      @instance.expects(:decompress).never
      @app.expects(:call).never
      @instance.expects(:cleanup).never
      @instance.call(@env)
    end

    should "cleanup if there was an error" do
      @env.error!(:foo)

      seq = sequence("sequence")
      @instance.expects(:setup_box_directory).in_sequence(seq).returns(true)
      @instance.expects(:decompress).in_sequence(seq)
      @app.expects(:call).with(@env)
      @instance.expects(:cleanup).once
      @instance.call(@env)
    end
  end

  context "cleaning up" do
    setup do
      @instance.stubs(:box_directory).returns("foo")
      File.stubs(:directory?).returns(false)
      FileUtils.stubs(:rm_rf)
    end

    should "do nothing if not a directory" do
      FileUtils.expects(:rm_rf).never
      @instance.cleanup
    end

    should "remove the directory if exists" do
      File.expects(:directory?).with(@instance.box_directory).once.returns(true)
      FileUtils.expects(:rm_rf).with(@instance.box_directory).once
      @instance.cleanup
    end
  end

  context "setting up the box directory" do
    setup do
      File.stubs(:directory?).returns(false)
      FileUtils.stubs(:mkdir_p)
    end

    should "error the environment if the box already exists" do
      File.expects(:directory?).returns(true)
      assert !@instance.setup_box_directory
      assert @env.error?
      assert_equal :box_already_exists, @env.error.first
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
      Archive::Tar::Minitar.expects(:unpack).with(@env["download.temp_path"], @env["box"].directory).once
      @instance.decompress
    end
  end
end
