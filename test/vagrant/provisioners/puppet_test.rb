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
      @action.expects(:share_manifests).once
      @action.prepare
    end
  end

  context "provisioning" do
    should "run the proper sequence of methods in order" do
      prov_seq = sequence("prov_seq")
      @action.expects(:verify_binary).with("puppet").once.in_sequence(prov_seq)
      @action.expects(:create_pp_path).once.in_sequence(prov_seq)
      @action.expects(:run_puppet_client).once.in_sequence(prov_seq)
      @action.provision!
    end
  end

  context "share manifests folder" do
    setup do
      @pp_path = "/tmp/vagrant-puppet"
      @action.stubs(:pp_path).returns(@pp_path)
    end

    should "share manifest folder" do
      @env.config.vm.expects(:share_folder).with("manifests", @pp_path, "manifests")
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

  context "running puppet client" do
    setup do
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "cd into the pp_path directory and run puppet" do
      @ssh.expects(:exec!).with("cd #{@env.config.puppet.pp_path} && sudo -E puppet #{@env.config.vm.box}.pp").once
      @action.run_puppet_client
    end

    should "check the exit status if that is given" do
      @ssh.stubs(:exec!).yields(nil, :exit_status, :foo)
      @ssh.expects(:check_exit_status).with(:foo, anything).once
      @action.run_puppet_client
    end
  end
end
