require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ProvisioningTest < Test::Unit::TestCase
  setup do
    # Stub upload so nothing happens
    Hobo::SSH.stubs(:upload!)

    vm = mock("vm")
    vm.stubs(:share_folder)
    @prov = Hobo::Provisioning.new(vm)
  end

  context "initializing" do
    should "setup shared folder on VM for the cookbooks" do
      File.expects(:expand_path).with(Hobo.config.chef.cookbooks_path, Hobo::Env.root_path).returns("foo")
      cookbooks_path = File.join(Hobo.config.chef.provisioning_path, "cookbooks")
      vm = mock("vm")
      vm.expects(:share_folder).with("hobo-provisioning", "foo", cookbooks_path)
      Hobo::Provisioning.new(vm)
    end
  end

  context "permissions on provisioning folder" do
    should "chown the folder to the ssh user" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo chown #{Hobo.config.ssh.username} #{Hobo.config.chef.provisioning_path}")
      Hobo::SSH.expects(:execute).yields(ssh)
      @prov.chown_provisioning_folder
    end
  end

  context "generating and uploading json" do
    should "convert the JSON config to JSON" do
      Hobo.config.chef.json.expects(:to_json).once.returns("foo")
      @prov.setup_json
    end

    should "upload a StringIO to dna.json" do
      Hobo.config.chef.json.expects(:to_json).once.returns("foo")
      StringIO.expects(:new).with("foo").returns("bar")
      File.expects(:join).with(Hobo.config.chef.provisioning_path, "dna.json").once.returns("baz")
      Hobo::SSH.expects(:upload!).with("bar", "baz").once
      @prov.setup_json
    end
  end
end
