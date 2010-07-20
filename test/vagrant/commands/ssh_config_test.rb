require "test_helper"

class CommandsSSHConfigTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::SSHConfig

    @env = mock_environment
    @env.stubs(:require_root_path)
    @instance = @klass.new(@env)
  end

  context "executing" do
    setup do
      @instance.stubs(:show_single)
    end

    should "require root path" do
      @env.expects(:require_root_path).once
      @instance.execute
    end

    should "call show_single with given argument" do
      @instance.expects(:show_single).with("foo").once
      @instance.execute(["foo"])
    end
  end

  context "showing a single entry" do
    setup do
      @ssh = mock("ssh")
      @ssh.stubs(:port).returns(2197)

      @bar = mock("vm")
      @bar.stubs(:env).returns(mock_environment)
      @bar.stubs(:ssh).returns(@ssh)

      @vms = {:bar => @bar}
      @env.stubs(:multivm?).returns(true)
      @env.stubs(:vms).returns(@vms)

      @data = {
        :host_key => "vagrant",
        :ssh_user => @bar.env.config.ssh.username,
        :ssh_port => @bar.ssh.port,
        :private_key_path => @bar.env.config.ssh.private_key_path
      }

      @instance.stubs(:puts)
    end

    should "error if name is nil and multivm" do
      @env.stubs(:multivm?).returns(true)
      @instance.expects(:error_and_exit).with(:ssh_config_multivm).once
      @instance.show_single(nil)
    end

    should "error if the VM is not found" do
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => "foo").once
      @instance.show_single("foo")
    end

    should "output rendered template" do
      result = mock("result")
      Vagrant::Util::TemplateRenderer.expects(:render).with("ssh_config", @data).returns(result)

      @instance.expects(:puts).with(result).once
      @instance.show_single(:bar)
    end

    should "render with the given host name if given" do
      host = "foo"
      @data[:host_key] = host
      Vagrant::Util::TemplateRenderer.expects(:render).with("ssh_config", @data)
      @instance.execute(["bar", "--host", host])
    end
  end
end
