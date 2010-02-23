require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class AddBoxActionTest < Test::Unit::TestCase
  setup do
    @wrapper_vm, @vm, @action = mock_action(Vagrant::Actions::Box::Add)
    mock_config
  end

  # TODO: Everything, once add does anything.
end
