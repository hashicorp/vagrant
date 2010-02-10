require File.join(File.dirname(__FILE__), '..', 'test_helper')

class ProvisioningTest < Test::Unit::TestCase
  setup do
    # Stub upload so nothing happens
    Vagrant::SSH.stubs(:upload!)

    vm = mock("vm")
    vm.stubs(:share_folder)
    @prov = Vagrant::Provisioning.new(vm)
  end

  context "initializing" do
    should "setup shared folder on VM for the cookbooks" do
      File.expects(:expand_path).with(Vagrant.config.chef.cookbooks_path, Vagrant::Env.root_path).returns("foo")
      Vagrant::Provisioning.any_instance.expects(:cookbooks_path).returns("bar")
      vm = mock("vm")
      vm.expects(:share_folder).with("vagrant-provisioning", "foo", "bar")
      Vagrant::Provisioning.new(vm)
    end

    should "return the proper cookbook path" do
      cookbooks_path = File.join(Vagrant.config.chef.provisioning_path, "cookbooks")
      assert_equal cookbooks_path, @prov.cookbooks_path
    end
  end

  context "permissions on provisioning folder" do
    should "chown the folder to the ssh user" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo chown #{Vagrant.config.ssh.username} #{Vagrant.config.chef.provisioning_path}")
      Vagrant::SSH.expects(:execute).yields(ssh)
      @prov.chown_provisioning_folder
    end
  end

  context "generating and uploading json" do
    should "convert the JSON config to JSON" do
      Vagrant.config.chef.json.expects(:to_json).once.returns("foo")
      @prov.setup_json
    end

    should "upload a StringIO to dna.json" do
      Vagrant.config.chef.json.expects(:to_json).once.returns("foo")
      StringIO.expects(:new).with("foo").returns("bar")
      File.expects(:join).with(Vagrant.config.chef.provisioning_path, "dna.json").once.returns("baz")
      Vagrant::SSH.expects(:upload!).with("bar", "baz").once
      @prov.setup_json
    end
  end

  context "generating and uploading chef solo configuration file" do
    should "upload properly generate the configuration file using configuration data" do
      expected_config = <<-config
file_cache_path "#{Vagrant.config.chef.provisioning_path}"
cookbook_path "#{@prov.cookbooks_path}"
config

      StringIO.expects(:new).with(expected_config).once
      @prov.setup_solo_config
    end

    should "upload this file as solo.rb to the provisioning folder" do
      @prov.expects(:cookbooks_path).returns("cookbooks")
      StringIO.expects(:new).returns("foo")
      File.expects(:join).with(Vagrant.config.chef.provisioning_path, "solo.rb").once.returns("bar")
      Vagrant::SSH.expects(:upload!).with("foo", "bar").once
      @prov.setup_solo_config
    end
  end

  context "running chef solo" do
    should "cd into the provisioning directory and run chef solo" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("cd #{Vagrant.config.chef.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json").once
      Vagrant::SSH.expects(:execute).yields(ssh)
      @prov.run_chef_solo
    end
  end
end
