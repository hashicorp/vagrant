require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ImportActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @import = mock_action(Vagrant::Actions::Import)

    VirtualBox::VM.stubs(:import)
  end

  should "run in a busy block" do
    Vagrant::Busy.expects(:busy).once
    @import.execute!
  end

  should "invoke an around callback around the import" do
    @mock_vm.expects(:invoke_around_callback).with(:import).once
    @import.execute!
  end

  should "call import on VirtualBox::VM with the proper base" do
    VirtualBox::VM.expects(:import).once
    @import.execute!
  end

  should "set the resulting VM as the VM of the Vagrant VM object" do
    new_vm = mock("new_vm")
    @mock_vm.expects(:vm=).with(new_vm).once
    VirtualBox::VM.expects(:import).returns(new_vm)
    @import.execute!
  end
end
