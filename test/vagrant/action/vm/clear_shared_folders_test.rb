require "test_helper"

class ClearSharedFoldersVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ClearSharedFolders
    @app, @env = action_env

    @vm = mock("vm")
    @env["vm"] = @vm

    @internal_vm = mock("internal")
    @vm.stubs(:vm).returns(@internal_vm)

    @instance = @klass.new(@app, @env)
  end

  context "calling" do
    setup do
      @shared_folder = mock("shared_folder")
      @shared_folders = [@shared_folder]
      @internal_vm.stubs(:shared_folders).returns(@shared_folders)
      @env["config"].vm.stubs(:customize).yields(@internal_vm)
    end

    should "call destroy on each shared folder then reload" do
      destroy_seq = sequence("destroy")
      @shared_folders.each do |sf|
        sf.expects(:destroy).once.in_sequence(destroy_seq)
      end

      @app.expects(:call).with(@env).once
      @instance.call(@env)
    end
  end
end
