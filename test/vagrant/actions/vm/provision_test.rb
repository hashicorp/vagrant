require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class ProvisionActionTest < Test::Unit::TestCase
  setup do
    @mock_vm, @vm, @action = mock_action(Vagrant::Actions::VM::Provision)

    Vagrant::SSH.stubs(:execute)
    Vagrant::SSH.stubs(:upload!)

    mock_config
  end

  context "shared folders" do
    should "setup shared folder on VM for the cookbooks" do
      File.expects(:expand_path).with(Vagrant.config.chef.cookbooks_path, Vagrant::Env.root_path).returns("foo")
      @action.expects(:cookbooks_path).returns("bar")
      assert_equal ["vagrant-provisioning", "foo", "bar"], @action.collect_shared_folders
    end
  end

  context "cookbooks path" do
    should "return the proper cookbook path" do
      cookbooks_path = File.join(Vagrant.config.chef.provisioning_path, "cookbooks")
      assert_equal cookbooks_path, @action.cookbooks_path
    end
  end

  context "permissions on provisioning folder" do
    should "chown the folder to the ssh user" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo chown #{Vagrant.config.ssh.username} #{Vagrant.config.chef.provisioning_path}")
      Vagrant::SSH.expects(:execute).yields(ssh)
      @action.chown_provisioning_folder
    end
  end

  context "generating and uploading json" do
    should "convert the JSON config to JSON" do
      Hash.any_instance.expects(:to_json).once.returns("foo")
      @action.setup_json
    end

    should "add the project directory to the JSON" do
      Vagrant::SSH.expects(:upload!).with do |json, path|
        data = JSON.parse(json.read)
        assert_equal Vagrant.config.vm.project_directory, data["project_directory"]
        true
      end

      @action.setup_json
    end

    should "upload a StringIO to dna.json" do
      StringIO.expects(:new).with(anything).returns("bar")
      File.expects(:join).with(Vagrant.config.chef.provisioning_path, "dna.json").once.returns("baz")
      Vagrant::SSH.expects(:upload!).with("bar", "baz").once
      @action.setup_json
    end
  end

  context "generating and uploading chef solo configuration file" do
    should "upload properly generate the configuration file using configuration data" do
      expected_config = <<-config
file_cache_path "#{Vagrant.config.chef.provisioning_path}"
cookbook_path "#{@action.cookbooks_path}"
config

      StringIO.expects(:new).with(expected_config).once
      @action.setup_solo_config
    end

    should "upload this file as solo.rb to the provisioning folder" do
      @action.expects(:cookbooks_path).returns("cookbooks")
      StringIO.expects(:new).returns("foo")
      File.expects(:join).with(Vagrant.config.chef.provisioning_path, "solo.rb").once.returns("bar")
      Vagrant::SSH.expects(:upload!).with("foo", "bar").once
      @action.setup_solo_config
    end
  end

  context "running chef solo" do
    should "cd into the provisioning directory and run chef solo" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("cd #{Vagrant.config.chef.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json").once
      Vagrant::SSH.expects(:execute).yields(ssh)
      @action.run_chef_solo
    end
  end
end
