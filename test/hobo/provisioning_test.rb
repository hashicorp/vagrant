require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ProvisioningTest < Test::Unit::TestCase
  context "initializing" do
    should "setup shared folder on VM" do
      File.expects(:expand_path).with(Hobo.config.chef.cookbooks_path, Hobo::Env.root_path).returns("foo")
      vm = mock("vm")
      vm.expects(:share_folder).with("hobo-provisioning", "foo", Hobo.config.chef.provisioning_path)
      Hobo::Provisioning.new(vm)
    end
  end
end
