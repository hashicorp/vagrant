require "test_helper"

class PackageGeneralActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::General::Package
    @app, @env = action_env

    @vm = mock("vm")
    @env["vm"] = @vm
  end

  context "initializing" do
    setup do
      @tar_path = "foo"
      File.stubs(:exist?).returns(false)
      @klass.any_instance.stubs(:tar_path).returns(@tar_path)
    end

    should "initialize fine" do
      @klass.new(@app, @env)
    end

    should "set the output path to configured by default" do
      @klass.new(@app, @env)
      assert_equal @env["config"].package.name, @env["package.output"]
    end

    should "not set the output path if it is already set" do
      @env["package.output"] = "foo"
      @klass.new(@app, @env)
      assert_equal "foo", @env["package.output"]
    end

    should "set the included files to empty by default" do
      @klass.new(@app, @env)
      assert_equal [], @env["package.include"]
    end

    should "not set the include path if it is already set" do
      @env["package.include"] = "foo"
      @klass.new(@app, @env)
      assert_equal "foo", @env["package.include"]
    end
  end

  context "with an instance" do
    setup do
      File.stubs(:exist?).returns(false)
      File.stubs(:directory?).returns(true)
      @instance = @klass.new(@app, @env)

      @env["package.directory"] = "foo"
    end

    context "calling" do
      should "call the proper methods then continue chain" do
        seq = sequence("seq")
        @instance.expects(:verify_files_to_copy).in_sequence(seq).returns(true)
        @instance.expects(:compress).in_sequence(seq)
        @app.expects(:call).with(@env).in_sequence(seq)
        @instance.call(@env)
      end

      should "halt the chain if the output file already exists" do
        File.expects(:exist?).returns(true)
        @app.expects(:call).never
        assert_raises(Vagrant::Errors::PackageOutputExists) {
          @instance.call(@env)
        }
      end

      should "halt the chain if directory isn't set" do
        @env["package.directory"] = nil
        @app.expects(:call).never
        assert_raises(Vagrant::Errors::PackageRequiresDirectory) {
          @instance.call(@env)
        }
      end

      should "halt the chain if directory doesn't exist" do
        File.expects(:directory?).with(@env["package.directory"]).returns(false)
        @app.expects(:call).never
        assert_raises(Vagrant::Errors::PackageRequiresDirectory) {
          @instance.call(@env)
        }
      end
    end

    context "cleaning up" do
      setup do
        File.stubs(:exist?).returns(false)
        File.stubs(:delete)

        @instance.stubs(:tar_path).returns("foo")
      end

      should "do nothing if the file doesn't exist" do
        File.expects(:exist?).with(@instance.tar_path).returns(false)
        File.expects(:delete).never

        @instance.recover(@env)
      end

      should "delete the packaged box if it exists" do
        File.expects(:exist?).returns(true)
        File.expects(:delete).with(@instance.tar_path).once

        @instance.recover(@env)
      end
    end

    context "files to copy" do
      setup do
        @env["package.include"] = []
        @package_dir = Pathname.new(@env["package.directory"]).join("include")
      end

      should "have included files whole path if relative" do
        path = "lib/foo"
        @env["package.include"] = [path]
        result = @instance.files_to_copy
        assert_equal @package_dir.join(path), result[path]
      end

      should "have the filename if an absolute path" do
        path = "/foo/bar"
        @env["package.include"] = [path]
        result = @instance.files_to_copy
        assert_equal @package_dir.join("bar"), result[path]
      end

      should "include the Vagrantfile if specified" do
        @env["package.vagrantfile"] = "foo"
        result = @instance.files_to_copy
        assert_equal @package_dir.join("_Vagrantfile"), result["foo"]
      end
    end

    context "verifying files to copy" do
      setup do
        @env["package.include"] = ["foo"]
        File.stubs(:exist?).returns(true)
      end

      should "error if included file is not found" do
        File.expects(:exist?).with("foo").returns(false)
        assert_raises(Vagrant::Errors::PackageIncludeMissing) {
          @instance.verify_files_to_copy
        }
      end

      should "return true if all exist" do
        assert_nothing_raised {
          assert @instance.verify_files_to_copy
        }
      end
    end

    context "copying include files" do
      setup do
        @env["package.include"] = []
      end

      should "do nothing if no include files are specified" do
        assert @env["package.include"].empty?
        FileUtils.expects(:mkdir_p).never
        FileUtils.expects(:cp).never
        @instance.copy_include_files
      end

      should "create the include directory and copy files to it" do
        @env["package.include"] = ["/foo/bar", "lib/foo"]
        seq = sequence("seq")
        @instance.files_to_copy.each do |from, to|
          FileUtils.expects(:mkdir_p).with(to.parent).in_sequence(seq)
          File.expects(:directory?).with(from).returns(false).in_sequence(seq)
          FileUtils.expects(:cp).with(from, to).in_sequence(seq)
        end

        @instance.copy_include_files
      end

      should "create the include directory and recursively copy globbed files to it" do
        @env["package.include"] = ["foo*.txt"]
        seq = sequence("seq")
        @instance.files_to_copy.each do |from, to|
          FileUtils.expects(:mkdir_p).with(to.parent).in_sequence(seq)
          File.expects(:directory?).with(from).returns(true).in_sequence(seq)
          Dir.expects(:glob).with(from).returns(from).in_sequence(seq)
          FileUtils.expects(:cp_r).with(from, to.parent).in_sequence(seq)
        end

        @instance.copy_include_files
      end
    end

    context "compression" do
      setup do
        @env["package.include"] = []

        @tar_path = "foo"
        @instance.stubs(:tar_path).returns(@tar_path)

        @pwd = "bar"
        FileUtils.stubs(:pwd).returns(@pwd)
        FileUtils.stubs(:cd)

        @file = mock("file")
        File.stubs(:open).yields(@file)

        @output = mock("output")
        @tar = Archive::Tar::Minitar
        Archive::Tar::Minitar::Output.stubs(:open).yields(@output)
        @tar.stubs(:pack_file)

        @instance.stubs(:copy_include_files)
      end

      should "open the tar file with the tar path properly" do
        File.expects(:open).with(@tar_path, Vagrant::Util::Platform.tar_file_options).once
        @instance.compress
      end

      should "open tar file" do
        Archive::Tar::Minitar::Output.expects(:open).with(@file).once
        @instance.compress
      end

      #----------------------------------------------------------------
      # Methods below this comment test the block yielded by Minitar open
      #----------------------------------------------------------------
      should "cd to the directory and append the directory" do
        @files = []
        compress_seq = sequence("compress_seq")

        FileUtils.expects(:pwd).once.returns(@pwd).in_sequence(compress_seq)
        @instance.expects(:copy_include_files).once.in_sequence(compress_seq)
        FileUtils.expects(:cd).with(@env["package.directory"]).in_sequence(compress_seq)
        Dir.expects(:glob).returns(@files).in_sequence(compress_seq)

        5.times do |i|
          file = mock("file#{i}")
          @tar.expects(:pack_file).with(file, @output).once.in_sequence(compress_seq)
          @files << file
        end

        FileUtils.expects(:cd).with(@pwd).in_sequence(compress_seq)
        @instance.compress
      end

      should "pop back to the current directory even if an exception is raised" do
        cd_seq = sequence("cd_seq")
        FileUtils.expects(:cd).with(@env["package.directory"]).raises(Exception).in_sequence(cd_seq)
        FileUtils.expects(:cd).with(@pwd).in_sequence(cd_seq)

        assert_raises(Exception) {
          @instance.compress
        }
      end
    end

    context "tar path" do
      should "return proper path" do
        assert_equal File.join(FileUtils.pwd, @env["package.output"]), @instance.tar_path
      end
    end
  end
end
