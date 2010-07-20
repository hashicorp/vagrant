require "test_helper"

class ClearSharedFoldersVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ClearSharedFolders
    @app, @env = mock_action_data

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    should "call the proper methods in sequence" do
      seq = sequence("seq")
      @instance.expects(:clear_shared_folders).once.in_sequence(seq)
      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end
  end

  context "clearing shared folders" do
    setup do
      @shared_folder = mock("shared_folder")
      @shared_folders = [@shared_folder]
      @internal_vm.stubs(:shared_folders).returns(@shared_folders)
    end

    should "call destroy on each shared folder then reload" do
      destroy_seq = sequence("destroy")
      @shared_folders.each do |sf|
        sf.expects(:destroy).once.in_sequence(destroy_seq)
      end

      @vm.expects(:reload!).once.in_sequence(destroy_seq)
      @instance.clear_shared_folders
    end

    should "do nothing if no shared folders existed" do
      @shared_folders.clear
      @vm.expects(:reload!).never
      @instance.clear_shared_folders
    end
  end
end
