require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ChefProvisionerTest < Test::Unit::TestCase
  setup do
    @action = Vagrant::Provisioners::Chef.new

    Vagrant::SSH.stubs(:execute)
    Vagrant::SSH.stubs(:upload!)

    mock_config
  end

  context "preparing" do
    should "raise an ActionException" do
      assert_raises(Vagrant::Actions::ActionException) {
        @action.prepare
      }
    end
  end

  context "config" do
    setup do
      @config = Vagrant::Provisioners::Chef::ChefConfig.new
      @config.json = "HEY"
    end

    should "not include the 'json' key in the config dump" do
      result = JSON.parse(@config.to_json)
      assert !result.has_key?("json")
    end
  end

  context "permissions on provisioning folder" do
    should "create and chown the folder to the ssh user" do
      ssh_seq = sequence("ssh_seq")
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo mkdir -p #{Vagrant.config.chef.provisioning_path}").once.in_sequence(ssh_seq)
      ssh.expects(:exec!).with("sudo chown #{Vagrant.config.ssh.username} #{Vagrant.config.chef.provisioning_path}").once.in_sequence(ssh_seq)
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
      Vagrant.config.chef.json = { :foo => "BAR" }
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
      File.expects(:join).with(Vagrant.config.chef.provisioning_path, "dna.json").once.returns("baz")
      Vagrant::SSH.expects(:upload!).with("bar", "baz").once
      @action.setup_json
    end
  end
end
