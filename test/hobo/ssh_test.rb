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
      Kernel.expects(:exec).with("#{@script} #{ssh[:uname]} #{ssh[:pass]} #{ssh[:host]} #{port}")
      Hobo::SSH.connect
    end

    test "should call exec with supplied params" do
      args = {:uname => 'bar', :pass => 'baz', :host => 'bak', :port => 'bag'}
      Kernel.expects(:exec).with("#{@script} #{args[:uname]} #{args[:pass]} #{args[:host]} #{args[:port]}")
      Hobo::SSH.connect(args)
    end
  end

  context "net-ssh interaction" do
    should "call net::ssh.start with the proper names" do
      Net::SSH.expects(:start).with("localhost", Hobo.config[:ssh][:uname], anything).once
      Hobo::SSH.execute
    end
  end

  context "checking if host is up" do
    should "pingecho the server" do
      port = Hobo.config.vm.forwarded_ports[Hobo.config.ssh.forwarded_port_key][:hostport]
      Ping.expects(:pingecho).with("localhost", 1, port).once
      Hobo::SSH.up?
    end
  end
end
