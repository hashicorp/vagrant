require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ChefSoloProvisionerTest < Test::Unit::TestCase
  setup do
    @action = Vagrant::Provisioners::ChefSolo.new

    Vagrant::SSH.stubs(:execute)
    Vagrant::SSH.stubs(:upload!)

    mock_config
  end

  context "provisioning" do
    should "run the proper sequence of methods in order" do
      prov_seq = sequence("prov_seq")
      @action.expects(:chown_provisioning_folder).once.in_sequence(prov_seq)
      @action.expects(:setup_json).once.in_sequence(prov_seq)
      @action.expects(:setup_solo_config).once.in_sequence(prov_seq)
      @action.expects(:run_chef_solo).once.in_sequence(prov_seq)
      @action.provision!
    end
  end

  context "shared folders" do
    should "setup shared folder on VM for the cookbooks" do
      File.expects(:expand_path).with(Vagrant.config.chef.cookbooks_path, Vagrant::Env.root_path).returns("foo")
      @action.expects(:cookbooks_path).returns("bar")
      Vagrant.config.vm.expects(:share_folder).with("vagrant-chef-solo", "bar", "foo").once
      @action.prepare
    end
  end

  context "cookbooks path" do
    should "return the proper cookbook path" do
      cookbooks_path = File.join(Vagrant.config.chef.provisioning_path, "cookbooks")
      assert_equal cookbooks_path, @action.cookbooks_path
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
