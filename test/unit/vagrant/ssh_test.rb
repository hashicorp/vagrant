require "test_helper"

class SshTest < Test::Unit::TestCase
  def mock_ssh
    @env = vagrant_env.vms[:default].env
    @network_adapters = []
    @vm = mock("vm")
    @vm.stubs(:network_adapters).returns(@network_adapters)
    @env.vm.stubs(:vm).returns(@vm)

    @ssh = Vagrant::SSH.new(@env)
  end

  setup do
    VirtualBox.stubs(:version).returns("4.1.0")
  end

  context "connecting to external SSH" do
    setup do
      mock_ssh
      @ssh.stubs(:check_key_permissions)
      @ssh.stubs(:port).returns(2222)
      @ssh.stubs(:safe_exec)
      @ssh.stubs(:run_interactive)
      #Kernel.stubs(:system).returns(true)
    end

    should "raise an exception if SSH is not found" do
      Kernel.stubs(:system).returns(false)
      Kernel.expects(:system).returns(false).with() do |command|
        assert command =~ /^which ssh/
        true
      end

      assert_raises(Vagrant::Errors::SSHUnavailable) {
        @ssh.connect
      }
    end

    should "check key permissions prior to exec" do
      exec_seq = sequence("exec_seq")
      @ssh.expects(:check_key_permissions).with(@env.config.ssh.private_key_path).once.in_sequence(exec_seq)
      @ssh.expects(:safe_exec).in_sequence(exec_seq)
      @ssh.connect
    end

    should "call exec with defaults when no options are supplied" do
      ssh_exec_expect(@ssh.port,
                      @env.config.ssh.private_key_path,
                      @env.config.ssh.username,
                      @env.config.ssh.host)do |args|
        assert args =~ /-o ControlMaster=auto/, args.inspect
        assert args =~ /-o ControlPath=~\/\.ssh\/vagrant-ssh-(.*)-%r@%h:%p/, args.inspect
        assert args =~ /-o KeepAlive=yes/, args.inspect
        assert args =~ /-o ServerAliveInterval=60/, args.inspect
        assert args =~ /-o ConnectTimeout=2/, args.inspect
      end
      @ssh.connect
    end

    should "call exec with supplied params" do
      args = {:username => 'bar', :private_key_path => 'baz', :host => 'bak'}
      ssh_exec_expect(@ssh.port, args[:private_key_path], args[:username], args[:host])
      @ssh.connect(args)
    end

    should "add forward agent option if enabled" do
      @env.config.ssh.forward_agent = true
      ssh_exec_expect(@ssh.port,
                      @env.config.ssh.private_key_path,
                      @env.config.ssh.username,
                      @env.config.ssh.host) do |args|
        assert args =~ /-o ForwardAgent=yes/
      end
      @ssh.connect
    end

    should "add forward X11 option if enabled" do
      @env.config.ssh.forward_x11 = true
      ssh_exec_expect(@ssh.port,
                      @env.config.ssh.private_key_path,
                      @env.config.ssh.username,
                      @env.config.ssh.host) do |args|
        assert args =~ /-o ForwardX11=yes/
      end
      @ssh.connect
    end

    should "add ControlMaster option if multiplexing enabled" do
      @env.config.ssh.shared_connections = true
      ssh_exec_expect(@ssh.port,
                      @env.config.ssh.private_key_path,
                      @env.config.ssh.username,
                      @env.config.ssh.host) do |args|
        assert args =~ /-o ControlMaster=auto/
      end
      @ssh.connect
    end

    should "add ControlPath option if multiplexing enabled" do
      @env.config.ssh.shared_connections = true
      ssh_exec_expect(@ssh.port,
                      @env.config.ssh.private_key_path,
                      @env.config.ssh.username,
                      @env.config.ssh.host) do |args|
        assert args =~ /-o ControlPath=~\/.ssh\/vagrant-ssh-(.*)-%r@%h:%p/
      end
      @ssh.connect
    end

    should "add ControlMaster option if multiplexing disabled" do
      @env.config.ssh.shared_connections = false
      ssh_exec_expect(@ssh.port,
                      @env.config.ssh.private_key_path,
                      @env.config.ssh.username,
                      @env.config.ssh.host) do |args|
        assert args =~ /-o ControlMaster=no/, args.inspect
      end
      @ssh.connect
    end

    should "not add ControlPath option if multiplexing disabled" do
      @env.config.ssh.shared_connections = false
      ssh_exec_expect(@ssh.port,
                      @env.config.ssh.private_key_path,
                      @env.config.ssh.username,
                      @env.config.ssh.host) do |args|
        assert args !=~ /-o ControlPath/
      end
      @ssh.connect
    end

    context "checking windows" do
      should "error and exit if the platform is windows" do
        Vagrant::Util::Platform.stubs(:windows?).returns(true)
        assert_raises(Vagrant::Errors::SSHUnavailableWindows) { @ssh.connect }
      end

      should "not error and exit if the platform is anything other that windows" do
        Vagrant::Util::Platform.stubs(:windows?).returns(false)
        assert_nothing_raised { @ssh.connect }
      end
    end

    def ssh_exec_expect(port, key_path, uname, host)
      @ssh.expects(:safe_exec).with() do |arg|
        assert arg =~ /^ssh/, "ssh command expected"
        assert arg =~ /-p #{port}/, "-p #{port} expected"
        assert arg =~ /-i #{key_path}/, "-i #{key_path} expected"
        assert arg =~ /#{uname}@#{host}/, "#{uname}@{host} expected"
        yield arg if block_given?
        true
      end
    end
  end

  context "executing ssh commands" do
    setup do
      mock_ssh
      @ssh.stubs(:check_key_permissions)
      @ssh.stubs(:port).returns(80)
    end

    should "check for an existing SSH connection, then attempt to connect" do
      seq = sequence("seq")
      @ssh.expects(:control_master_alive?).once.in_sequence(seq)
      @ssh.expects(:start_control_master).once.in_sequence(seq)
      @ssh.expects(:get_connection).once.in_sequence(seq)
      @ssh.expects(:create_connection).with(is_a(Hash)).once.in_sequence(seq)
      @ssh.execute
    end

    should "check key permissions then attempt to make connection" do
      seq = sequence("seq")
      @ssh.expects(:check_key_permissions).with(@env.config.ssh.private_key_path).once.in_sequence(seq)
      @ssh.expects(:interactive_connect).once.in_sequence(seq)
      @ssh.expects(:type).once.in_sequence(seq)
      @ssh.create_connection({})
    end

    #TODO improve my <whataver-library> test-fu
    #should "call vagrant::ssh.interactive_connect with the proper options" do
    #  options = {:private_key_path => @env.config.ssh.private_key_path }
    #  @ssh.expects(:interactive_connect).once.with(options) do |opts|
    #    assert_equal @ssh.port, opts[:port]
    #    assert_equal [@env.config.ssh.private_key_path], opts[:keys]
    #    assert opts[:keys_only]
    #    true
    #  end
    #  @ssh.execute
    #end

    should "forward agent if configured" do
      @env.config.ssh.forward_agent = true
      @ssh.expects(:type).once
      @ssh.expects(:interactive_connect).once.with() do |opts|
        assert opts[:forward_agent]
        true
      end

      @ssh.create_connection({})
    end

    should "use custom host if set" do
      @env.config.ssh.host = "foo"
      @ssh.expects(:type).once
      @ssh.expects(:interactive_connect).with(anything).once
      @ssh.create_connection({})
    end

    #It does, session is no longer a separate class, so self is the 'session'
    #should "yield an SSH session object" do
    #  raw = mock("raw")
    #  @ssh.expects(:interactive_connect).returns(raw)
    #  @ssh.execute do |ssh|
    #    assert ssh.is_a?(Vagrant::SSH)
    #    assert_equal raw, ssh.session
    #  end
    #end
  end

  context "SCPing files to the remote host" do
    setup do
      mock_ssh
    end

    should "use Vagrant::SSH execute to setup an SCP connection and upload" do
      scp = mock("scp")
      ssh = mock("ssh")
      sess = mock("session")
      ssh.stubs(:session).returns(sess)
      @ssh.stubs(:port).returns(2222)
      @ssh.expects(:scp_command).with(@ssh.build_options, "foo", "bar" ).returns(scp).once
      @ssh.expects(:run_simple).returns(true).once
      @ssh.upload!("foo", "bar")
    end
  end

  context "checking if host is up" do
    setup do
      mock_ssh
      @ssh.stubs(:check_key_permissions)
      @ssh.stubs(:port).returns(2222)
    end

    should "return true if SSH connection works" do
      @ssh.expects(:run_simple).yields(0)
      assert @ssh.up?
    end

    # TODO: Piggyback off Arbua's exits status assertions (requires RSpec ?)'
    #should "return false if the connection is refused" do
    #  @ssh.expects(:interactive_connect).times(5).raises(Errno::ECONNREFUSED)
    #  @ssh.assert_not_exit_status(0)
    #end

    #Todo: timeout is not Vagrants code, essentially this is a test of the config values
    #should "specifity the timeout as an option to execute" do
    #  @ssh.expects(:run_simple).returns(true).with() do |opts|
    #    assert_equal @env.config.ssh.timeout, opts[:timeout], "#{@env.config.ssh.timeout} and #{opts[:timeout]}"
    #    true
    #  end
    #
    #  assert @ssh.up?
    #end

    should "only get the port once (in the main thread)" do
      @ssh.expects(:port).once.returns(2222)
      @ssh.stubs(:run_simple).returns(true)
      @ssh.up?
    end
  end

  context "getting the ssh port" do
    setup do
      mock_ssh
    end

    should "return the port given in options if it exists" do
      assert_equal "47", @ssh.port({ :port => "47" })
    end
  end

  context "checking key permissions" do
    setup do
      mock_ssh
      @ssh.stubs(:file_perms)

      @key_path = "foo"


      @stat = mock("stat")
      @stat.stubs(:owned?).returns(true)
      File.stubs(:stat).returns(@stat)

      Vagrant::Util::Platform.stubs(:windows?).returns(false)
    end

    should "do nothing if on windows" do
      Vagrant::Util::Platform.stubs(:windows?).returns(true)
      File.expects(:stat).never
      @ssh.check_key_permissions(@key_path)
    end

    should "do nothing if the user is not the owner" do
      @stat.expects(:owned?).returns(false)
      File.expects(:chmod).never
      @ssh.check_key_permissions(@key_path)
    end

    should "do nothing if the file perms equal 600" do
      @ssh.expects(:file_perms).with(@key_path).returns("600")
      File.expects(:chmod).never
      @ssh.check_key_permissions(@key_path)
    end

    should "chmod the file if the file perms aren't 600" do
      perm_sequence = sequence("perm_seq")
      @ssh.expects(:file_perms).returns("900").in_sequence(perm_sequence)
      File.expects(:chmod).with(0600, @key_path).once.in_sequence(perm_sequence)
      @ssh.expects(:file_perms).returns("600").in_sequence(perm_sequence)
      assert_nothing_raised { @ssh.check_key_permissions(@key_path) }
    end

    should "error and exit if the resulting chmod doesn't work" do
      perm_sequence = sequence("perm_seq")
      @ssh.expects(:file_perms).returns("900").in_sequence(perm_sequence)
      File.expects(:chmod).with(0600, @key_path).once.in_sequence(perm_sequence)
      @ssh.expects(:file_perms).returns("900").in_sequence(perm_sequence)
      assert_raises(Vagrant::Errors::SSHKeyBadPermissions) { @ssh.check_key_permissions(@key_path) }
    end

    should "error and exit if a bad file perm is raised" do
      @ssh.expects(:file_perms).with(@key_path).returns("900")
      File.expects(:chmod).raises(Errno::EPERM)
      assert_raises(Vagrant::Errors::SSHKeyBadPermissions) { @ssh.check_key_permissions(@key_path) }
    end
  end

  context "getting file permissions" do
    setup do
      mock_ssh
    end

    should "return the last 3 characters of the file mode" do
      path = "foo"
      mode = "10000foo"
      stat = mock("stat")
      File.expects(:stat).with(path).returns(stat)
      stat.expects(:mode).returns(mode)
      @ssh.expects(:sprintf).with("%o", mode).returns(mode)
      assert_equal path, @ssh.file_perms(path)
    end
  end
end
