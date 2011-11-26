require "test_helper"

class SshTest < Test::Unit::TestCase
  def mock_ssh
    @env = vagrant_env.vms[:default].env
    @network_adapters = []
    @vm = mock("vm")
    @vm.stubs(:network_adapters).returns(@network_adapters)
    @env.vm.stubs(:vm).returns(@vm)

    @ssh = Vagrant::SSH.new(@env)
    @session = mock("session")
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
      Kernel.stubs(:system).returns(true)
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
                      @env.config.ssh.host)
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

    should "check key permissions then attempt to start connection" do
      seq = sequence("seq")
      @ssh.expects(:check_key_permissions).with(@env.config.ssh.private_key_path).once.in_sequence(seq)
      Net::SSH.expects(:start).once.in_sequence(seq)
      @ssh.execute
    end

    should "call net::ssh.start with the proper names" do
      Net::SSH.expects(:start).once.with() do |host, username, opts|
        assert_equal @env.config.ssh.host, host
        assert_equal @env.config.ssh.username, username
        assert_equal @ssh.port, opts[:port]
        assert_equal [@env.config.ssh.private_key_path], opts[:keys]
        assert opts[:keys_only]
        true
      end
      @ssh.execute
    end

    should "forward agent if configured" do
      @env.config.ssh.forward_agent = true
      Net::SSH.expects(:start).once.with() do |host, username, opts|
        assert opts[:forward_agent]
        true
      end

      @ssh.execute
    end

    should "use custom host if set" do
      @env.config.ssh.host = "foo"
      Net::SSH.expects(:start).with(@env.config.ssh.host, @env.config.ssh.username, anything).once
      @ssh.execute
    end

    should "yield an SSH session object" do
      raw = mock("raw")
      Net::SSH.expects(:start).returns(raw)
      @ssh.execute do |ssh|
        assert ssh.is_a?(Vagrant::SSH::Session)
        assert_equal raw, ssh.session
      end
    end
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
      scp.expects(:upload!).with("foo", "bar").once
      Net::SCP.expects(:new).with(ssh.session).returns(scp).once
      @ssh.expects(:execute).yields(ssh).once
      @ssh.upload!("foo", "bar")
    end
  end

  context "checking if host is up" do
    setup do
      mock_ssh
      @ssh.stubs(:check_key_permissions)
      @ssh.stubs(:port).returns(2222)
      @session.stubs(:exec!).returns("hello\n")
    end

    should "return false if SSH connection times out" do
      @env.config.ssh.timeout = 0.5

      Net::SSH.stubs(:start).with() do
        # Sleep here to artificially fake timeout
        sleep 1
        true
      end

      assert !@ssh.up?
    end

    should "return false if the connection is refused" do
      Net::SSH.expects(:start).times(@env.config.ssh.max_tries).raises(Errno::ECONNREFUSED)
      assert_nothing_raised {
        assert !@ssh.up?
      }
    end

    should "specify the timeout as an option to execute" do
      @ssh.expects(:execute).yields(@session).with() do |opts|
        assert_equal @env.config.ssh.timeout, opts[:timeout]
        true
      end

      assert @ssh.up?
    end

    should "error and exit if a Net::SSH::AuthenticationFailed is raised" do
      @ssh.expects(:execute).raises(Net::SSH::AuthenticationFailed)
      assert_raises(Vagrant::Errors::SSHAuthenticationFailed) { @ssh.up? }
    end

    should "only get the port once (in the main thread)" do
      @ssh.expects(:port).once.returns(2222)
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
