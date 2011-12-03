require "test_helper"

class CleanMachineFolderVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::CleanMachineFolder
    @app, @env = action_env

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "clean machine folder then continue chain" do
      seq = sequence("seq")
      @instance.expects(:clean_machine_folder).in_sequence(seq)
      @app.expects(:call).with(@env).in_sequence(seq)
      @instance.call(@env)
    end
  end

  context "cleaning the folder" do
    setup do
      @machine_folder = "/foo/bar/baz"
      @folder = File.join(@machine_folder, "*")
      VirtualBox::Global.global.system_properties.stubs(:default_machine_folder).returns(@machine_folder)
      File.stubs(:file?).returns(true)
    end

    should "ignore all non-directories" do
      folders = %W[foo bar baz]
      Dir.expects(:[]).with(@folder).returns(folders)
      folders.each do |f|
        File.expects(:directory?).with(f).returns(false)
      end

      FileUtils.expects(:rm_rf).never

      @instance.clean_machine_folder
    end

    should "delete directories with only .vbox-prev files" do
      folders = {
        "sfoo" => %W[foo bar baz.vbox-prev],
        "sbar" => %W[foo.vbox-prev]
      }

      Dir.expects(:[]).with(@folder).returns(folders.keys)
      folders.each do |folder, subfolders|
        File.expects(:directory?).with(folder).returns(true)
        Dir.expects(:[]).with("#{folder}/**/*").returns(subfolders)
      end

      FileUtils.expects(:rm_rf).never
      FileUtils.expects(:rm_rf).with("sbar").once
      @instance.clean_machine_folder
    end

    should "delete directories with only subdirectories" do
      folders = {
        "sfoo" => %W[foo bar],
        "sbar" => %W[foo.vbox-prev]
      }

      File.stubs(:file?).returns(false)
      Dir.expects(:[]).with(@folder).returns(folders.keys)
      folders.each do |folder, subfolders|
        File.expects(:directory?).with(folder).returns(true)
        Dir.expects(:[]).with("#{folder}/**/*").returns(subfolders)
      end

      FileUtils.expects(:rm_rf).never
      FileUtils.expects(:rm_rf).with("sfoo").once
      FileUtils.expects(:rm_rf).with("sbar").once

      @instance.clean_machine_folder
    end

    should "do nothing if folder is < 10 characters" do
      VirtualBox::Global.global.system_properties.stubs(:default_machine_folder).returns("foo")
      Dir.expects(:[]).never

      @instance.clean_machine_folder
    end
  end
end
