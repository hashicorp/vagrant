require "test_helper"

class PackageVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::Package
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)
  end

  context "initializing" do
    setup do
      @tar_path = "foo"
      File.stubs(:exist?).returns(false)
      @klass.any_instance.stubs(:tar_path).returns(@tar_path)
    end

    should "initialize fine" do
      @klass.new(@app, @env)
      assert !@env.error?
    end

    should "error the environment if the output file exists" do
      File.stubs(:exist?).with(@tar_path).returns(true)
      @klass.new(@app, @env)
      assert @env.error?
      assert_equal :box_file_exists, @env.error.first
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

    should "not set the output path if it is already set" do
      @env["package.include"] = "foo"
      @klass.new(@app, @env)
      assert_equal "foo", @env["package.include"]
    end
  end

  context "with an instance" do
    setup do
      File.stubs(:exist?).returns(false)
      @instance = @klass.new(@app, @env)

      @env["export.temp_dir"] = "foo"
    end

    context "calling" do
      should "call the proper methods then continue chain" do
        seq = sequence("seq")
        @instance.expects(:verify_included_files).in_sequence(seq).returns(true)
        @instance.expects(:compress).in_sequence(seq)
        @app.expects(:call).with(@env).in_sequence(seq)
        @instance.expects(:cleanup).never

        @instance.call(@env)
      end

      should "halt the chain if verify failed" do
        @instance.expects(:verify_included_files).returns(false)
        @instance.expects(:compress).never
        @app.expects(:call).never

        @instance.call(@env)
      end

      should "halt the chain if export didn't run" do
        @env["export.temp_dir"] = nil
        @app.expects(:call).never
        @instance.call(@env)

        assert @env.error?
        assert_equal :package_requires_export, @env.error.first
      end

      should "run cleanup if environment errors" do
        seq = sequence("seq")
        @instance.expects(:verify_included_files).in_sequence(seq).returns(true)
        @instance.expects(:compress).in_sequence(seq)
        @app.expects(:call).with(@env).in_sequence(seq)
        @instance.expects(:cleanup).in_sequence(seq)

        @env.error!(:foo)
        @instance.call(@env)
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

        @instance.cleanup
      end

      should "delete the packaged box if it exists" do
        File.expects(:exist?).returns(true)
        File.expects(:delete).with(@instance.tar_path).once

        @instance.cleanup
      end
    end

    context "verifying included files" do
      setup do
        @env["package.include"] = ["foo"]
        File.stubs(:exist?).returns(true)
      end

      should "error if included file is not found" do
        File.expects(:exist?).with("foo").returns(false)
        assert !@instance.verify_included_files
        assert @env.error?
        assert_equal :package_include_file_doesnt_exist, @env.error.first
      end

      should "return true if all exist" do
        assert @instance.verify_included_files
        assert !@env.error?
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
        include_dir = File.join(@env["export.temp_dir"], "include")
        copy_seq = sequence("copy_seq")
        FileUtils.expects(:mkdir_p).with(include_dir).once.in_sequence(copy_seq)

        5.times do |i|
          file = mock("f#{i}")
          @env["package.include"] << file
          FileUtils.expects(:cp).with(file, include_dir).in_sequence(copy_seq)
        end

        @instance.copy_include_files
      end
    end

    context "creating vagrantfile" do
      setup do
        @network_adapter = mock("nic")
        @network_adapter.stubs(:mac_address).returns("mac_address")
        @internal_vm.stubs(:network_adapters).returns([@network_adapter])
      end

      should "write the rendered vagrantfile to temp_path Vagrantfile" do
        f = mock("file")
        rendered = mock("rendered")
        File.expects(:open).with(File.join(@env["export.temp_dir"], "Vagrantfile"), "w").yields(f)
        Vagrant::Util::TemplateRenderer.expects(:render).returns(rendered).with("package_Vagrantfile", {
                                                                                  :base_mac => @internal_vm.network_adapters.first.mac_address
                                                                                })
        f.expects(:write).with(rendered)

        @instance.create_vagrantfile
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
        @instance.stubs(:create_vagrantfile)
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
        @instance.expects(:create_vagrantfile).once.in_sequence(compress_seq)
        FileUtils.expects(:cd).with(@env["export.temp_dir"]).in_sequence(compress_seq)
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
        FileUtils.expects(:cd).with(@env["export.temp_dir"]).raises(Exception).in_sequence(cd_seq)
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
