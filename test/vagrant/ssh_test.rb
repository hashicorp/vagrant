require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase
  def mock_ssh
    @env = mock_environment do |config|
      yield config if block_given?
    end

    @ssh = Vagrant::SSH.new(@env)
  end

  context "connecting to external SSH" do
    setup do
      mock_ssh
      @ssh.stubs(:check_key_permissions)
      @ssh.stubs(:error_and_exit)
      Kernel.stubs(:exec)

      Vagrant::Util::Platform.stubs(:leopard?).returns(false)
    end

    should "check key permissions prior to exec" do
      exec_seq = sequence("exec_seq")
      @ssh.expects(:check_key_permissions).with(@env.config.ssh.private_key_path).once.in_sequence(exec_seq)
      Kernel.expects(:exec).in_sequence(exec_seq)
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
      args = {:username => 'bar', :private_key_path => 'baz', :host => 'bak', :port => 'bag'}
      ssh_exec_expect(args[:port], args[:private_key_path], args[:username], args[:host])
      @ssh.connect(args)
    end

    context "on leopard" do
      setup do
        Vagrant::Util::Platform.stubs(:leopard?).returns(true)
      end

      should "fork, exec, and wait" do
        pid = mock("pid")
        @ssh.expects(:fork).once.returns(pid)
        Process.expects(:wait).with(pid)

        @ssh.connect
      end
    end

    context "checking windows" do
      should "error and exit if the platform is windows" do
        Mario::Platform.expects(:windows?).returns(true)
        @ssh.expects(:error_and_exit).with do |error_name, opts|
          opts[:key_path] && opts[:ssh_port]
        end
        @ssh.connect
      end

      should "not error and exit if the platform is anything other that windows" do
        Mario::Platform.expects(:windows?).returns(false)
        @ssh.expects(:error_and_exit).never
        @ssh.connect
      end
    end

    def ssh_exec_expect(port, key_path, uname, host)
      Kernel.expects(:exec).with() do |arg|
        assert arg =~ /^ssh/
        assert arg =~ /-p #{port}/
        assert arg =~ /-i #{key_path}/
        assert arg =~ /#{uname}@#{host}/
        # TODO options not tested for as they may be removed
        true
      end
    end
  end

  context "executing ssh commands" do
    setup do
      mock_ssh
    end

    should "call net::ssh.start with the proper names" do
      Net::SSH.expects(:start).once.with() do |host, username, opts|
        assert_equal @env.config.ssh.host, host
        assert_equal @env.config.ssh.username, username
        assert_equal @ssh.port, opts[:port]
        assert_equal [@env.config.ssh.private_key_path], opts[:keys]
        true
      end
      @ssh.execute
    end

    should "use custom host if set" do
      @env.config.ssh.host = "foo"
      Net::SSH.expects(:start).with(@env.config.ssh.host, @env.config.ssh.username, anything).once
      @ssh.execute
    end
  end

  context "SCPing files to the remote host" do
    setup do
      mock_ssh
    end

    should "use Vagrant::SSH execute to setup an SCP connection and upload" do
      scp = mock("scp")
      ssh = mock("ssh")
      scp.expects(:upload!).with("foo", "bar").once
      Net::SCP.expects(:new).with(ssh).returns(scp).once
      @ssh.expects(:execute).yields(ssh).once
      @ssh.upload!("foo", "bar")
    end
  end

  context "checking if host is up" do
    setup do
      mock_ssh
    end

    should "return true if SSH connection works" do
      Net::SSH.expects(:start).yields("success")
      assert @ssh.up?
    end

    should "return false if SSH connection times out" do
      Net::SSH.expects(:start)
      assert !@ssh.up?
    end

    should "allow the thread the configured timeout time" do
      @thread = mock("thread")
      @thread.stubs(:[])
      Thread.expects(:new).returns(@thread)
      @thread.expects(:join).with(@env.config.ssh.timeout).once
      @ssh.up?
    end

    should "return false if the connection is refused" do
      Net::SSH.expects(:start).raises(Errno::ECONNREFUSED)
      assert_nothing_raised {
        assert !@ssh.up?
      }
    end

    should "return false if the connection is dropped" do
      Net::SSH.expects(:start).raises(Net::SSH::Disconnect)
      assert_nothing_raised {
        assert !@ssh.up?
      }
    end

    should "specifity the timeout as an option to execute" do
      @ssh.expects(:execute).with(:timeout => @env.config.ssh.timeout).yields(true)
      assert @ssh.up?
    end

    should "error and exit if a Net::SSH::AuthenticationFailed is raised" do
      @ssh.expects(:execute).raises(Net::SSH::AuthenticationFailed)
      @ssh.expects(:error_and_exit).with(:vm_ssh_auth_failed).once
      @ssh.up?
    end
  end

  context "getting the ssh port" do
    setup do
      mock_ssh
    end

    should "return the configured port by default" do
      assert_equal @env.config.vm.forwarded_ports[@env.config.ssh.forwarded_port_key][:hostport], @ssh.port
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
      @ssh.expects(:error_and_exit).never
      @ssh.check_key_permissions(@key_path)
    end

    should "error and exit if the resulting chmod doesn't work" do
      perm_sequence = sequence("perm_seq")
      @ssh.expects(:file_perms).returns("900").in_sequence(perm_sequence)
      File.expects(:chmod).with(0600, @key_path).once.in_sequence(perm_sequence)
      @ssh.expects(:file_perms).returns("900").in_sequence(perm_sequence)
      @ssh.expects(:error_and_exit).once.with(:ssh_bad_permissions, :key_path => @key_path).in_sequence(perm_sequence)
      @ssh.check_key_permissions(@key_path)
    end

    should "error and exit if a bad file perm is raised" do
      @ssh.expects(:file_perms).with(@key_path).returns("900")
      File.expects(:chmod).raises(Errno::EPERM)
      @ssh.expects(:error_and_exit).once.with(:ssh_bad_permissions, :key_path => @key_path)
      @ssh.check_key_permissions(@key_path)
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
