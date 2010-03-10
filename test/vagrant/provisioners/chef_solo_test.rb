require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ChefSoloProvisionerTest < Test::Unit::TestCase
  setup do
    @action = Vagrant::Provisioners::ChefSolo.new

    Vagrant::SSH.stubs(:execute)
    Vagrant::SSH.stubs(:upload!)

    mock_config
  end

  context "config" do
    setup do
      @config = Vagrant::Provisioners::ChefSolo::CustomConfig.new
      @config.json = "HEY"
    end

    should "not include the 'json' key in the config dump" do
      result = JSON.parse(@config.to_json)
      assert !result.has_key?("json")
    end
  end

  context "shared folders" do
    should "setup shared folder on VM for the cookbooks" do
      File.expects(:expand_path).with(Vagrant.config.chef_solo.cookbooks_path, Vagrant::Env.root_path).returns("foo")
      @action.expects(:cookbooks_path).returns("bar")
      Vagrant.config.vm.expects(:share_folder).with("vagrant-chef-solo", "bar", "foo").once
      @action.prepare
    end
  end

  context "cookbooks path" do
    should "return the proper cookbook path" do
      cookbooks_path = File.join(Vagrant.config.chef_solo.provisioning_path, "cookbooks")
      assert_equal cookbooks_path, @action.cookbooks_path
    end
  end

  context "permissions on provisioning folder" do
    should "chown the folder to the ssh user" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo chown #{Vagrant.config.ssh.username} #{Vagrant.config.chef_solo.provisioning_path}")
      Vagrant::SSH.expects(:execute).yields(ssh)
      @action.chown_provisioning_folder
    end
  end

  context "generating and uploading json" do
    def assert_json
      Vagrant::SSH.expects(:upload!).with do |json, path|
        data = JSON.parse(json.read)
        yield data
        true
      end

      @action.setup_json
    end

    should "merge in the extra json specified in the config" do
      Vagrant.config.chef_solo.json = { :foo => "BAR" }
      assert_json do |data|
        assert_equal "BAR", data["foo"]
      end
    end

    should "add the directory as a special case to the JSON" do
      assert_json do |data|
        assert_equal Vagrant.config.vm.project_directory, data["vagrant"]["directory"]
      end
    end

    should "add the config to the JSON" do
      assert_json do |data|
        assert_equal Vagrant.config.vm.project_directory, data["vagrant"]["config"]["vm"]["project_directory"]
      end
    end

    should "upload a StringIO to dna.json" do
      StringIO.expects(:new).with(anything).returns("bar")
      File.expects(:join).with(Vagrant.config.chef_solo.provisioning_path, "dna.json").once.returns("baz")
      Vagrant::SSH.expects(:upload!).with("bar", "baz").once
      @action.setup_json
    end
  end

  context "generating and uploading chef solo configuration file" do
    should "upload properly generate the configuration file using configuration data" do
      expected_config = <<-config
file_cache_path "#{Vagrant.config.chef_solo.provisioning_path}"
cookbook_path "#{@action.cookbooks_path}"
config

      StringIO.expects(:new).with(expected_config).once
      @action.setup_solo_config
    end

    should "upload this file as solo.rb to the provisioning folder" do
      @action.expects(:cookbooks_path).returns("cookbooks")
      StringIO.expects(:new).returns("foo")
      File.expects(:join).with(Vagrant.config.chef_solo.provisioning_path, "solo.rb").once.returns("bar")
      Vagrant::SSH.expects(:upload!).with("foo", "bar").once
      @action.setup_solo_config
    end
  end

  context "running chef solo" do
    should "cd into the provisioning directory and run chef solo" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("cd #{Vagrant.config.chef_solo.provisioning_path} && sudo chef-solo -c solo.rb -j dna.json").once
      Vagrant::SSH.expects(:execute).yields(ssh)
      @action.run_chef_solo
    end
  end
end
