require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase
  setup do
    mock_config
  end

  context "connecting to SSH" do
    setup do
      Vagrant::SSH.stubs(:check_key_permissions)
    end

    should "check key permissions prior to exec" do
      exec_seq = sequence("exec_seq")
      Vagrant::SSH.expects(:check_key_permissions).with(Vagrant.config.ssh.private_key_path).once.in_sequence(exec_seq)
      Kernel.expects(:exec).in_sequence(exec_seq)
      Vagrant::SSH.connect
    end

    should "call exec with defaults when no options are supplied" do
      ssh = Vagrant.config.ssh
      ssh_exec_expect(Vagrant::SSH.port,
                      Vagrant.config.ssh.private_key_path,
                      Vagrant.config.ssh.username,
                      Vagrant.config.ssh.host)
      Vagrant::SSH.connect
    end

    should "call exec with supplied params" do
      args = {:username => 'bar', :private_key_path => 'baz', :host => 'bak', :port => 'bag'}
      ssh_exec_expect(args[:port], args[:private_key_path], args[:username], args[:host])
      Vagrant::SSH.connect(args)
    end

    def ssh_exec_expect(port, key_path, uname, host)
    Kernel.expects(:exec).with() do |arg|
        assert arg =~ /^ssh/
        assert arg =~ /-p #{port}/
        assert arg =~ /-i #{key_path}/
        assert arg =~ /#{uname}@#{host}/
        # TODO options not tested for as they may be removed, they may be removed
        true
      end
    end
  end

  context "executing ssh commands" do
    should "call net::ssh.start with the proper names" do
      Net::SSH.expects(:start).once.with() do |host, username, opts|
        assert_equal Vagrant.config.ssh.host, host
        assert_equal Vagrant.config.ssh.username, username
        assert_equal Vagrant::SSH.port, opts[:port]
        assert_equal [Vagrant.config.ssh.private_key_path], opts[:keys]
        true
      end
      Vagrant::SSH.execute
    end

    should "use custom host if set" do
      Vagrant.config.ssh.host = "foo"
      Net::SSH.expects(:start).with(Vagrant.config.ssh.host, Vagrant.config.ssh.username, anything).once
      Vagrant::SSH.execute
    end
  end

  context "SCPing files to the remote host" do
    should "use Vagrant::SSH execute to setup an SCP connection and upload" do
      scp = mock("scp")
      ssh = mock("ssh")
      scp.expects(:upload!).with("foo", "bar").once
      Net::SCP.expects(:new).with(ssh).returns(scp).once
      Vagrant::SSH.expects(:execute).yields(ssh).once
      Vagrant::SSH.upload!("foo", "bar")
    end
  end

  context "checking if host is up" do
    setup do
      mock_config
    end

    should "return true if SSH connection works" do
      Net::SSH.expects(:start).yields("success")
      assert Vagrant::SSH.up?
    end

    should "return false if SSH connection times out" do
      Net::SSH.expects(:start)
      assert !Vagrant::SSH.up?
    end

    should "allow the thread the configured timeout time" do
      @thread = mock("thread")
      @thread.stubs(:[])
      Thread.expects(:new).returns(@thread)
      @thread.expects(:join).with(Vagrant.config.ssh.timeout).once
      Vagrant::SSH.up?
    end

    should "return false if the connection is refused" do
      Net::SSH.expects(:start).raises(Errno::ECONNREFUSED)
      assert_nothing_raised {
        assert !Vagrant::SSH.up?
      }
    end

    should "return false if the connection is dropped" do
      Net::SSH.expects(:start).raises(Net::SSH::Disconnect)
      assert_nothing_raised {
        assert !Vagrant::SSH.up?
      }
    end

    should "specifity the timeout as an option to execute" do
      Vagrant::SSH.expects(:execute).with(:timeout => Vagrant.config.ssh.timeout).yields(true)
      assert Vagrant::SSH.up?
    end

    should "error and exit if a Net::SSH::AuthenticationFailed is raised" do
      Vagrant::SSH.expects(:execute).raises(Net::SSH::AuthenticationFailed)
      Vagrant::SSH.expects(:error_and_exit).with(:vm_ssh_auth_failed).once
      Vagrant::SSH.up?
    end
  end

  context "getting the ssh port" do
    should "return the configured port by default" do
      assert_equal Vagrant.config.vm.forwarded_ports[Vagrant.config.ssh.forwarded_port_key][:hostport], Vagrant::SSH.port
    end

    should "return the port given in options if it exists" do
      assert_equal "47", Vagrant::SSH.port({ :port => "47" })
    end
  end

  context "checking key permissions" do
    setup do
      @key_path = "foo"

      Vagrant::SSH.stubs(:file_perms)

      @stat = mock("stat")
      @stat.stubs(:owned?).returns(true)
      File.stubs(:stat).returns(@stat)
    end

    should "do nothing if the user is not the owner" do
      @stat.expects(:owned?).returns(false)
      File.expects(:chmod).never
      Vagrant::SSH.check_key_permissions(@key_path)
    end

    should "do nothing if the file perms equal 600" do
      Vagrant::SSH.expects(:file_perms).with(@key_path).returns("600")
      File.expects(:chmod).never
      Vagrant::SSH.check_key_permissions(@key_path)
    end

    should "chmod the file if the file perms aren't 600" do
      perm_sequence = sequence("perm_seq")
      Vagrant::SSH.expects(:file_perms).returns("900").in_sequence(perm_sequence)
      File.expects(:chmod).with(0600, @key_path).once.in_sequence(perm_sequence)
      Vagrant::SSH.expects(:file_perms).returns("600").in_sequence(perm_sequence)
      Vagrant::SSH.expects(:error_and_exit).never
      Vagrant::SSH.check_key_permissions(@key_path)
    end

    should "error and exit if the resulting chmod doesn't work" do
      perm_sequence = sequence("perm_seq")
      Vagrant::SSH.expects(:file_perms).returns("900").in_sequence(perm_sequence)
      File.expects(:chmod).with(0600, @key_path).once.in_sequence(perm_sequence)
      Vagrant::SSH.expects(:file_perms).returns("900").in_sequence(perm_sequence)
      Vagrant::SSH.expects(:error_and_exit).once.with(:ssh_bad_permissions, :key_path => @key_path).in_sequence(perm_sequence)
      Vagrant::SSH.check_key_permissions(@key_path)
    end

    should "error and exit if a bad file perm is raised" do
      Vagrant::SSH.expects(:file_perms).with(@key_path).returns("900")
      File.expects(:chmod).raises(Errno::EPERM)
      Vagrant::SSH.expects(:error_and_exit).once.with(:ssh_bad_permissions, :key_path => @key_path)
      Vagrant::SSH.check_key_permissions(@key_path)
    end
  end

  context "getting file permissions" do
    should "return the last 3 characters of the file mode" do
      path = "foo"
      mode = "10000foo"
      stat = mock("stat")
      File.expects(:stat).with(path).returns(stat)
      stat.expects(:mode).returns(mode)
      Vagrant::SSH.expects(:sprintf).with("%o", mode).returns(mode)
      assert_equal path, Vagrant::SSH.file_perms(path)
    end
  end
end
