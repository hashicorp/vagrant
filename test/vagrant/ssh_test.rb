require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase
  setup do
    mock_config
  end

  context "connecting to SSH" do
    test "should call exec with defaults when no options are supplied" do
      ssh = Vagrant.config.ssh
      ssh_exec_expect(Vagrant::SSH.port,
                      Vagrant.config.ssh.private_key_path,
                      Vagrant.config.ssh.username,
                      Vagrant.config.ssh.host)
      Vagrant::SSH.connect
    end

    test "should call exec with supplied params" do
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
end
