require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ChefServerProvisionerTest < Test::Unit::TestCase
  setup do
    @action = Vagrant::Provisioners::ChefServer.new

    Vagrant::SSH.stubs(:execute)
    Vagrant::SSH.stubs(:upload!)

    mock_config
  end

  context "provisioning" do
    should "run the proper sequence of methods in order" do
      prov_seq = sequence("prov_seq")
      @action.expects(:chown_provisioning_folder).once.in_sequence(prov_seq)
      @action.expects(:create_client_key_folder).once.in_sequence(prov_seq)
      @action.expects(:upload_validation_key).once.in_sequence(prov_seq)
      @action.expects(:setup_json).once.in_sequence(prov_seq)
      @action.expects(:setup_config).once.in_sequence(prov_seq)
      @action.expects(:run_chef_client).once.in_sequence(prov_seq)
      @action.provision!
    end
  end

  context "preparing" do
    setup do
      File.stubs(:file?).returns(true)
    end

    should "not raise an exception if validation_key_path is set" do
      mock_config do |config|
        config.chef.validation_key_path = "7"
      end

      assert_nothing_raised { @action.prepare }
    end

    should "raise an exception if validation_key_path is nil" do
      mock_config do |config|
        config.chef.validation_key_path = nil
      end

      assert_raises(Vagrant::Actions::ActionException) {
        @action.prepare
      }
    end

    should "not raise an exception if validation_key_path does exist" do
      mock_config do |config|
        config.chef.validation_key_path = "7"
      end

      File.expects(:file?).with(Vagrant.config.chef.validation_key_path).returns(true)
      assert_nothing_raised { @action.prepare }
    end

    should "raise an exception if validation_key_path doesn't exist" do
      mock_config do |config|
        config.chef.validation_key_path = "7"
      end

      File.expects(:file?).with(Vagrant.config.chef.validation_key_path).returns(false)
      assert_raises(Vagrant::Actions::ActionException) {
        @action.prepare
      }
    end

    should "not raise an exception if chef_server_url is set" do
      mock_config do |config|
        config.chef.chef_server_url = "7"
      end

      assert_nothing_raised { @action.prepare }
    end

    should "raise an exception if chef_server_url is nil" do
      mock_config do |config|
        config.chef.chef_server_url = nil
      end

      assert_raises(Vagrant::Actions::ActionException) {
        @action.prepare
      }
    end
  end

  context "creating the client key folder" do
    setup do
      @raw_path = "/foo/bar/baz.pem"
      mock_config do |config|
        config.chef.client_key_path = @raw_path
      end

      @path = Pathname.new(@raw_path)
    end

    should "create the folder using the dirname of the path" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo mkdir -p #{@path.dirname}").once
      Vagrant::SSH.expects(:execute).yields(ssh)
      @action.create_client_key_folder
    end
  end

  context "uploading the validation key" do
    should "upload the validation key to the provisioning path" do
      @action.expects(:validation_key_path).once.returns("foo")
      @action.expects(:guest_validation_key_path).once.returns("bar")
      Vagrant::SSH.expects(:upload!).with("foo", "bar").once
      @action.upload_validation_key
    end
  end

  context "the validation key path" do
    should "expand the configured key path" do
      result = mock("result")
      File.expects(:expand_path).with(Vagrant.config.chef.validation_key_path, Vagrant::Env.root_path).once.returns(result)
      assert_equal result, @action.validation_key_path
    end
  end

  context "the guest validation key path" do
    should "be the provisioning path joined with validation.pem" do
      result = mock("result")
      File.expects(:join).with(Vagrant.config.chef.provisioning_path, "validation.pem").once.returns(result)
      assert_equal result, @action.guest_validation_key_path
    end
  end

  context "generating and uploading chef client configuration file" do
    setup do
      @action.stubs(:guest_validation_key_path).returns("foo")
    end

    should "upload properly generate the configuration file using configuration data" do
      expected_config = <<-config
log_level          :info
log_location       STDOUT
ssl_verify_mode    :verify_none
chef_server_url    "#{Vagrant.config.chef.chef_server_url}"

validation_client_name "#{Vagrant.config.chef.validation_client_name}"
validation_key         "#{@action.guest_validation_key_path}"
client_key             "#{Vagrant.config.chef.client_key_path}"

file_store_path    "/srv/chef/file_store"
file_cache_path    "/srv/chef/cache"

pid_file           "/var/run/chef/chef-client.pid"

Mixlib::Log::Formatter.show_time = true
config

      StringIO.expects(:new).with(expected_config).once
      @action.setup_config
    end

    should "upload this file as client.rb to the provisioning folder" do
      StringIO.expects(:new).returns("foo")
      File.expects(:join).with(Vagrant.config.chef.provisioning_path, "client.rb").once.returns("bar")
      Vagrant::SSH.expects(:upload!).with("foo", "bar").once
      @action.setup_config
    end
  end

  context "running chef client" do
    should "cd into the provisioning directory and run chef client" do
      ssh = mock("ssh")
      ssh.expects(:exec!).with("cd #{Vagrant.config.chef.provisioning_path} && sudo chef-client -c client.rb -j dna.json").once
      Vagrant::SSH.expects(:execute).yields(ssh)
      @action.run_chef_client
    end
  end
end
