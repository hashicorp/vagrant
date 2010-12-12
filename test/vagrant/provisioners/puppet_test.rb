require "test_helper"

class PuppetProvisionerTest < Test::Unit::TestCase
  setup do
    @action_env = Vagrant::Action::Environment.new(vagrant_env.vms[:default].env)

    @action = Vagrant::Provisioners::Puppet.new(@action_env)
    @env = @action.env
    @vm = @action.vm
  end

  context "preparing" do
    should "share manifests" do
      @action.expects(:check_manifest_dir).once
      @action.expects(:share_manifests).once
      @action.prepare
    end
  end

  context "provisioning" do
    should "run the proper sequence of methods in order" do
      prov_seq = sequence("prov_seq")
      @action.expects(:verify_binary).with("puppet").once.in_sequence(prov_seq)
      @action.expects(:create_pp_path).once.in_sequence(prov_seq)
      @action.expects(:set_manifest).once.in_sequence(prov_seq)
      @action.expects(:run_puppet_client).once.in_sequence(prov_seq)
      @action.provision!
    end
  end

  context "check manifest_dir" do
    setup do 
      @env.config.puppet.manifests_path = "manifests"
    end

    should "should not create the manifest directory if it exists" do
      File.expects(:directory?).with(@env.config.puppet.manifests_path).returns(true)
      @action.check_manifest_dir
    end

    should "create the manifest directory if it does not exist" do
      File.stubs(:directory?).with(@env.config.puppet.manifests_path).returns(false)
      Dir.expects(:mkdir).with(@env.config.puppet.manifests_path).once
      @action.check_manifest_dir
    end
  end
  
  context "share manifests folder" do
    setup do
      @manifests_path = "manifests"
      @pp_path = "/tmp/vagrant-puppet"
      @action.stubs(:manifests_path).returns(@manifests_path)
      @action.stubs(:pp_path).returns(@pp_path)
    end

    should "share manifest folder" do
      @env.config.vm.expects(:share_folder).with("manifests", @pp_path, @manifests_path)
      @action.share_manifests
    end
  end

  context "verifying binary" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "verify binary exists" do
      binary = "foo"
      @ssh.expects(:exec!).with("which #{binary}", anything)
      @action.verify_binary(binary)
    end
  end

  context "create pp path" do
    should "create and chown the folder to the ssh user" do
      ssh_seq = sequence("ssh_seq")
      ssh = mock("ssh")
      ssh.expects(:exec!).with("sudo mkdir -p #{@env.config.puppet.pp_path}").once.in_sequence(ssh_seq)
      ssh.expects(:exec!).with("sudo chown #{@env.config.ssh.username} #{@env.config.puppet.pp_path}").once.in_sequence(ssh_seq)
      @vm.ssh.expects(:execute).yields(ssh)
      @action.create_pp_path
    end
  end

  context "setting the manifest" do
    setup do
      @env.config.puppet.stubs(:manifests_path).returns("manifests")
      @env.config.puppet.stubs(:manifest_file).returns("foo.pp")
      @env.config.vm.stubs(:box).returns("base")
    end

    should "set the manifest if it exists" do
      File.stubs(:exists?).with("#{@env.config.puppet.manifests_path}/#{@env.config.puppet.manifest_file}").returns(true)
      @action.set_manifest
    end
  
    should "raise an error if the manifest does not exist" do
      File.stubs(:exists?).with("#{@env.config.puppet.manifests_path}/#{@env.config.puppet.manifest_file}").returns(false)
      assert_raises(Vagrant::Provisioners::PuppetError) {
        @action.set_manifest
      }
    end
  end

  context "running puppet client" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "cd into the pp_path directory and run puppet" do
      @ssh.expects(:exec!).with("cd #{@env.config.puppet.pp_path} && sudo -E puppet  #{@manifest}").once
      @action.run_puppet_client
    end

    should "cd into the pp_path directory and run puppet with given options" do
      @env.config.puppet.options = ["--modulepath", "modules", "--verbose"]
      @ssh.expects(:exec!).with("cd #{@env.config.puppet.pp_path} && sudo -E puppet --modulepath modules --verbose #{@manifest}").once
      @action.run_puppet_client
    end

    should "check the exit status if that is given" do
      @ssh.stubs(:exec!).yields(nil, :exit_status, :foo)
      @ssh.expects(:check_exit_status).with(:foo, anything).once
      @action.run_puppet_client
    end
  end
end
