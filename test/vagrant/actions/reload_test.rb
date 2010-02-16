require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ReloadActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::Reload)
  end
end
