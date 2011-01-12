require "test_helper"

class PuppetProvisionerTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Provisioners::Puppet

    @action_env = Vagrant::Action::Environment.new(vagrant_env.vms[:default].env)

    @config = @klass::Config.new
    @action = @klass.new(@action_env, @config)
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
      @config.manifests_path = "manifests"
    end

    should "should not create the manifest directory if it exists" do
      File.expects(:directory?).with(@config.manifests_path).returns(true)
      @action.check_manifest_dir
    end

    should "create the manifest directory if it does not exist" do
      File.stubs(:directory?).with(@config.manifests_path).returns(false)
      Dir.expects(:mkdir).with(@config.manifests_path).once
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
      ssh.expects(:exec!).with("sudo mkdir -p #{@config.pp_path}").once.in_sequence(ssh_seq)
      ssh.expects(:exec!).with("sudo chown #{@env.config.ssh.username} #{@config.pp_path}").once.in_sequence(ssh_seq)
      @vm.ssh.expects(:execute).yields(ssh)
      @action.create_pp_path
    end
  end

  context "setting the manifest" do
    setup do
      @config.stubs(:manifests_path).returns("manifests")
      @config.stubs(:manifest_file).returns("foo.pp")
      @env.config.vm.stubs(:box).returns("base")
    end

    should "set the manifest if it exists" do
      File.stubs(:exists?).with("#{@config.manifests_path}/#{@config.manifest_file}").returns(true)
      @action.set_manifest
    end

    should "raise an error if the manifest does not exist" do
      File.stubs(:exists?).with("#{@config.manifests_path}/#{@config.manifest_file}").returns(false)
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
      @ssh.expects(:exec!).with("cd #{@config.pp_path} && sudo -E puppet  #{@manifest}").once
      @action.run_puppet_client
    end

    should "cd into the pp_path directory and run puppet with given options when given as an array" do
      @config.options = ["--modulepath", "modules", "--verbose"]
      @ssh.expects(:exec!).with("cd #{@config.pp_path} && sudo -E puppet --modulepath modules --verbose #{@manifest}").once
      @action.run_puppet_client
    end

    should "cd into the pp_path directory and run puppet with the options when given as a string" do
      @config.options = "--modulepath modules --verbose"
      @ssh.expects(:exec!).with("cd #{@config.pp_path} && sudo -E puppet --modulepath modules --verbose #{@manifest}").once
      @action.run_puppet_client
    end

    should "check the exit status if that is given" do
      @ssh.stubs(:exec!).yields(nil, :exit_status, :foo)
      @ssh.expects(:check_exit_status).with(:foo, anything).once
      @action.run_puppet_client
    end
  end
end
