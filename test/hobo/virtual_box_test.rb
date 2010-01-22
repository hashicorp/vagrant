require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VirtualBoxTest < Test::Unit::TestCase  
  setup do
    # Stub out command so nothing actually happens
    VirtualBox.stubs(:command)
  end
end