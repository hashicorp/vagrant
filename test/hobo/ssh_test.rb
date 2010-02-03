require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase
  setup do
    hobo_mock_config
  end

  context "hobo ssh" do
    setup do
      @script = Hobo::SSH::SCRIPT
    end

    test "should call exec with defaults when no options are supplied" do
      ssh = Hobo.config.ssh
      port = Hobo.config.vm.forwarded_ports[ssh.forwarded_port_key][:hostport]
      Kernel.expects(:exec).with("#{@script} #{ssh[:username]} #{ssh[:password]} #{ssh[:host]} #{port}")
      Hobo::SSH.connect
    end

    test "should call exec with supplied params" do
      args = {:username => 'bar', :password => 'baz', :host => 'bak', :port => 'bag'}
      Kernel.expects(:exec).with("#{@script} #{args[:username]} #{args[:password]} #{args[:host]} #{args[:port]}")
      Hobo::SSH.connect(args)
    end
  end

  context "net-ssh interaction" do
    should "call net::ssh.start with the proper names" do
      Net::SSH.expects(:start).with(Hobo.config.ssh.host, Hobo.config[:ssh][:username], anything).once
      Hobo::SSH.execute
    end

    should "use custom host if set" do
      Hobo.config.ssh.host = "foo"
      Net::SSH.expects(:start).with(Hobo.config.ssh.host, Hobo.config[:ssh][:username], anything).once
      Hobo::SSH.execute
    end
  end

  context "checking if host is up" do
    setup do
      hobo_mock_config
    end

    should "pingecho the server" do
      port = Hobo.config.vm.forwarded_ports[Hobo.config.ssh.forwarded_port_key][:hostport]
      Ping.expects(:pingecho).with(Hobo.config.ssh.host, 1, port).once
      Hobo::SSH.up?
    end

    should "use custom host if set" do
      port = Hobo.config.vm.forwarded_ports[Hobo.config.ssh.forwarded_port_key][:hostport]
      Hobo.config.ssh.host = "foo"
      Ping.expects(:pingecho).with(Hobo.config.ssh.host, 1, port).once
      Hobo::SSH.up?
    end
  end
end
