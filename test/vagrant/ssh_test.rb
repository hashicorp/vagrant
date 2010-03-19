require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase
  setup do
    mock_config
  end

  def mock_ssh
    @env = mock_environment do |config|
      yield config if block_given?
    end

    @ssh = Vagrant::SSH.new(@env)
  end

  context "connecting to external SSH" do
    setup do
      mock_ssh
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
end
