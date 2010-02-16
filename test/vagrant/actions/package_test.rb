require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class PackageActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::Package)
    mock_config
  end  
  
  should "setup and correct working directory and export to it" do
    working_dir = File.join(FileUtils.pwd, Vagrant.config.package.name)
    FileUtils.expects(:rm_r).with(working_dir)
    @action.expects(:compress)
    assert_equal @action.execute!, "#{working_dir}.box"
  end

  # TODO test compression once its finished
end
