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

  context "when importing with or without an ovf file as an argument" do
    # NOTE for both tests File.expects(:expand_path) makes mocha recurse and vomit

    should "default the ovf_file value to the vagrant base when not passed as an init argument" do\
      File.stubs(:expand_path)
      File.expand_path do |n|
        assert_equal n, Vagrant.config.vm.base
      end
      Vagrant::Actions::Import.new(@vm)
    end

    should "expand the ovf path and assign it when passed as a parameter" do
      File.stubs(:expand_path)
      File.expand_path do |n|
         assert_equal n, 'foo'
      end 
      Vagrant::Actions::Import.new(@vm, 'foo')
    end
  end
end
