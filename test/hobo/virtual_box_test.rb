require File.join(File.dirname(__FILE__), '..', 'test_helper')

class VirtualBoxTest < Test::Unit::TestCase  
  setup do
    # Stub out command so nothing actually happens
    VirtualBox.stubs(:command)
  end
  
  context "modifying VMs" do
    should "wrap double quotes around values with spaces" do
      # TODO: how to use mocha with regex expectations?
      #VirtualBox.expects(:command).with(/"my value"/)
      VirtualBox.modify(@name, "key", "my value")
    end
  end
end