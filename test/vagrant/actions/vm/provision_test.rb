require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ProvisionActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::VM::Provision)
    mock_config
  end
end
