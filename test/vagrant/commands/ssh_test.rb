require "test_helper"

class CommandsSSHTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::SSH

    @env = mock_environment
    @instance = @klass.new(@env)
  end

  context "executing" do
    should "connect to the given argument" do
      @instance.expects(:ssh_connect).with("foo").once
      @instance.execute(["foo"])
    end

    should "connect with nil name if none is given" do
      @instance.expects(:ssh_connect).with(nil).once
      @instance.execute
    end

    should "execute if commands are given" do
      @env.stubs(:vms).returns(:foo => mock("foo"))
      @instance.expects(:ssh_execute).with("foo", @env.vms[:foo]).once
      @instance.execute(["foo","-e","bar"])
    end

    should "execute over every VM if none is specified with a command" do
      vms = {
        :foo => mock("foo"),
        :bar => mock("bar")
      }

      @env.stubs(:vms).returns(vms)
      vms.each do |key, vm|
        @instance.expects(:ssh_execute).with(key, vm).once
      end

      @instance.execute(["--execute", "bar"])
    end
  end

  context "ssh executing" do
    setup do
      @name = :foo

      @ssh_conn = mock("connection")
      @ssh_conn.stubs(:exec!)

      @ssh = mock("ssh")
      @ssh.stubs(:execute).yields(@ssh_conn)

      @vm = mock("vm")
      @vm.stubs(:created?).returns(true)
      @vm.stubs(:ssh).returns(@ssh)
      @vm.stubs(:env).returns(@env)
    end

    should "error and exit if invalid VM given" do
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => @name).once
      @instance.ssh_execute(@name, nil)
    end

    should "error and exit if VM isn't created" do
      @vm.stubs(:created?).returns(false)
      @instance.expects(:error_and_exit).with(:environment_not_created).once
      @instance.ssh_execute(@name, @vm)
    end

    should "execute each command" do
      commands = [:a,:b,:c]
      @instance.stubs(:options).returns(:execute => commands)
      commands.each do |cmd|
        @ssh_conn.expects(:exec!).with(cmd).once
      end

      @instance.ssh_execute(@name, @vm)
    end
  end

  context "ssh connecting" do
    setup do
      @vm = mock("vm")
      @vm.stubs(:created?).returns(true)

      @vms = {:bar => @vm}
      @env.stubs(:vms).returns(@vms)
      @env.stubs(:multivm?).returns(false)
    end

    should "error and exit if no VM is specified and multivm and no primary VM" do
      @env.stubs(:multivm?).returns(true)
      @env.stubs(:primary_vm).returns(nil)
      @instance.expects(:error_and_exit).with(:ssh_multivm).once
      @instance.ssh_connect(nil)
    end

    should "use the primary VM if it exists and no name is specified" do
      vm = mock("vm")
      ssh = mock("ssh")
      vm.stubs(:created?).returns(true)
      vm.stubs(:ssh).returns(ssh)

      @env.stubs(:multivm?).returns(true)
      @env.stubs(:primary_vm).returns(vm)
      ssh.expects(:connect).once
      @instance.ssh_connect(nil)
    end

    should "error and exit if VM is nil" do
      @instance.expects(:error_and_exit).with(:unknown_vm, :vm => :foo).once
      @instance.ssh_connect(:foo)
    end

    should "error and exit if VM isn't created" do
      @vm.stubs(:created?).returns(false)
      @instance.expects(:error_and_exit).with(:environment_not_created).once
      @instance.ssh_connect(:bar)
    end

    should "ssh connect" do
      ssh = mock("ssh")
      @vm.stubs(:ssh).returns(ssh)
      ssh.expects(:connect)

      @instance.ssh_connect(:bar)
    end
  end
end
