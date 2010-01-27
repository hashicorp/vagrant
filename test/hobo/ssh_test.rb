require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase

  context "Hobo ssh" do
    setup do
      @handler = Hobo::SSH
      @script = Hobo::SSH::SCRIPT
    end
    
    test "should call exec with defaults when no options are supplied" do
      ssh = HOBO_MOCK_CONFIG[:ssh]
      Kernel.expects(:exec).with("#{@script} #{ssh[:uname]} #{ssh[:pass]} #{ssh[:host]} #{ssh[:port]}")
      Hobo::SSH.connect
    end

    test "should call exec with supplied params" do
      args = {:uname => 'bar', :pass => 'baz', :host => 'bak', :port => 'bag'}
      Kernel.expects(:exec).with("#{@script} #{args[:uname]} #{args[:pass]} #{args[:host]} #{args[:port]}")
      Hobo::SSH.connect(args)
    end
  end
end
