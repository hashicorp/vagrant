require "test_helper"

class PuppetServerProvisionerTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Provisioners::PuppetServer

    @action_env = Vagrant::Action::Environment.new(vagrant_env.vms[:default].env)

    @config = @klass::Config.new
    @action = @klass.new(@action_env, @config)
    @env = @action.env
    @vm = @action.vm
  end

  context "provisioning" do
    should "run the proper sequence of methods in order" do
      prov_seq = sequence("prov_seq")
      @action.expects(:verify_binary).with("puppetd").once.in_sequence(prov_seq)
      @action.expects(:run_puppetd_client).once.in_sequence(prov_seq)
      @action.provision!
    end
  end

  context "verifying binary" do
    setup do
      @ssh = mock("ssh")
      @shell = mock("shell")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "verify binary exists" do
      binary = "foo"
      @ssh.expects(:sudo!).with("which #{binary}", anything)
      @action.verify_binary(binary)
    end
  end

  context "running puppetd client" do
    setup do
      @cn = "puppet_node"
      @ssh = mock("ssh")
      @vm.ssh.stubs(:execute).yields(@ssh)
    end

    should "run the puppetd client" do
      @ssh.expects(:sudo!).with("puppetd  --server #{@config.puppet_server} --certname #{@cn}").once
      @action.run_puppetd_client
    end

    should "run puppetd with given options when given as an array" do
      @config.options = ["--modulepath", "modules", "--verbose"]
      @ssh.expects(:sudo!).with("puppetd --modulepath modules --verbose --server #{@config.puppet_server} --certname #{@cn}").once
      @action.run_puppetd_client
    end

    should "run puppetd with the options when given as a string" do
      @config.options = "--modulepath modules --verbose"
      @ssh.expects(:sudo!).with("puppetd --modulepath modules --verbose --server #{@config.puppet_server} --certname #{@cn}").once
      @action.run_puppetd_client
    end

    should "check the exit status if that is given" do
      @ssh.stubs(:sudo!).yields(nil, :exit_status, :foo)
      @ssh.expects(:check_exit_status).with(:foo, anything).once
      @action.run_puppetd_client
    end
  end
end
