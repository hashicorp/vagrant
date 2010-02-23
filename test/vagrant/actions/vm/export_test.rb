require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ExportActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Export)
    mock_config
  end

  should "setup and correct working directory and export to it" do
    new_dir = File.join(FileUtils.pwd, Vagrant.config.package.name)
    FileUtils.expects(:mkpath).with(new_dir).returns(new_dir)
    @wrapper_vm.expects(:export).with(File.join(new_dir, "#{Vagrant.config.package.name}.ovf"))
    @action.execute!


#FileUtils.expects(:rm_r).with(new_dir)


 #   assert_equal Vagrant::VM.new(@mock_vm).package(name, location), "#{new_dir}.box"
  end
end
