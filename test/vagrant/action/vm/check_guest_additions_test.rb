require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class CheckGuestAdditionsVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::CheckGuestAdditions
  end

  # TODO: This isn't tested.
end
