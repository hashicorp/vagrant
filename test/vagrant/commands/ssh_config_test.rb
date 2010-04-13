require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsSSHConfigTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::SSHConfig

    @persisted_vm = mock("persisted_vm")
    @persisted_vm.stubs(:execute!)

    @env = mock_environment
    @env.stubs(:require_persisted_vm)
    @env.stubs(:vm).returns(@persisted_vm)

    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @ssh = mock("ssh")
      @ssh.stubs(:port).returns(2197)
      @env.stubs(:ssh).returns(@ssh)
      @env.stubs(:require_root_path)

      @instance.stubs(:puts)

      @data = {
        :host_key => "vagrant",
        :ssh_user => @env.config.ssh.username,
        :ssh_port => @env.ssh.port,
        :private_key_path => @env.config.ssh.private_key_path
      }
    end

    should "require root path" do
      @env.expects(:require_root_path).once
      @instance.execute
    end

    should "output rendered template" do
      result = mock("result")
      Vagrant::Util::TemplateRenderer.expects(:render).with("ssh_config", @data).returns(result)

      @instance.expects(:puts).with(result).once
      @instance.execute
    end

    should "render with the given host name if given" do
      host = "foo"
      @data[:host_key] = host
      Vagrant::Util::TemplateRenderer.expects(:render).with("ssh_config", @data)
      @instance.execute(["--host", host])
    end
  end
end
