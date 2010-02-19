require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class PackageActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::Package)
    @action.to = '/foo/bar/baz'
    @action.name = 'bing'
    mock_config
  end  
  
  should "setup and correct working directory and export to it" do
    working_dir = File.join(@action.to, @action.name)
    FileUtils.expects(:rm_r).with(working_dir)
    @action.expects(:compress)
    assert_equal @action.execute!, "#{working_dir}.box"
  end

  should "return the target file and the proper extension for tar_path" do
    assert_equal File.join(@action.to, @action.name + Vagrant.config.package.extension), @action.tar_path
  end

  should "return the target working dir" do
    assert_equal File.join(@action.to, @action.name), @action.working_dir
  end

  # TODO test compression once its finished
end
