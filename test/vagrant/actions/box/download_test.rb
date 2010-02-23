require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class DownloadBoxActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::Box::Download)
    mock_config
  end
end
