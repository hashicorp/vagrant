require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase
  setup do
    mock_config
  end

  context "connecting to SSH" do
    setup do
      @script = Vagrant::SSH::SCRIPT
    end

    test "should call exec with defaults when no options are supplied" do
      ssh = Vagrant.config.ssh
      Kernel.expects(:exec).with("#{@script} #{ssh[:username]} #{ssh[:password]} #{ssh[:host]} #{Vagrant::SSH.port}")
      Vagrant::SSH.connect
    end

    test "should call exec with supplied params" do
      args = {:username => 'bar', :password => 'baz', :host => 'bak', :port => 'bag'}
      Kernel.expects(:exec).with("#{@script} #{args[:username]} #{args[:password]} #{args[:host]} #{args[:port]}")
      Vagrant::SSH.connect(args)
    end
  end

  context "executing ssh commands" do
    should "call net::ssh.start with the proper names" do
      Net::SSH.expects(:start).once.with() do |host, username, opts|
        assert_equal Vagrant.config.ssh.host, host
        assert_equal Vagrant.config.ssh.username, username
        assert_equal Vagrant::SSH.port, opts[:port]
        assert_equal Vagrant.config.ssh.password, opts[:password]
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

      @timeout = 7

      @thread = mock("thread")
      @thread.stubs(:[])
      @thread.stubs(:[]=)
      @thread.stubs(:join)
      Thread.stubs(:current).returns(@thread)
      Thread.stubs(:new).returns(@thread).yields

      Net::SSH.stubs(:start)
    end

    should "return the value of result in thread" do
      result = mock("result")
      @thread.expects(:[]).with(:result).returns(result)
      assert_equal result, Vagrant::SSH.up?
    end

    should "start SSH with proper configuration" do
      Net::SSH.expects(:start).with(Vagrant.config.ssh.host, Vagrant.config.ssh.username, :port => Vagrant::SSH.port, :password => Vagrant.config.ssh.password, :timeout => Vagrant.config.ssh.timeout).once
      Vagrant::SSH.up?
    end

    should "start SSH with proper timeout value if given" do
      Net::SSH.expects(:start).with(Vagrant.config.ssh.host, Vagrant.config.ssh.username, :port => Vagrant::SSH.port, :password => Vagrant.config.ssh.password, :timeout => @timeout).once
      Vagrant::SSH.up?(@timeout)
    end

    should "set result to true if SSH connection works" do
      @thread.expects(:[]=).with(:result, true)
      Net::SSH.expects(:start).yields("success")
      Vagrant::SSH.up?
    end

    should "set result to false if SSH connection times out" do
      @thread.expects(:[]=).with(:result, false)
      Net::SSH.expects(:start)
      Vagrant::SSH.up?
    end

    should "allow the thread the configured timeout time by default" do
      Thread.expects(:new).returns(@thread)
      @thread.expects(:join).with(Vagrant.config.ssh.timeout).once
      Vagrant::SSH.up?
    end

    should "allow the thread the given timeout time if given" do
      Thread.expects(:new).returns(@thread)
      @thread.expects(:join).with(@timeout).once
      Vagrant::SSH.up?(@timeout)
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
