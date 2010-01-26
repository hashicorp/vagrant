require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase

  context "Hobo ssh" do
    setup do
      @handler = Hobo::SSH
      @script = Hobo::SSH::SCRIPT
    end
    
    test "should call exec with defaults when no options are supplied" do
      # NOTE HOBO_MOCK_CONFIG only contains the :uname at this stage, adding further params will break this test
      Kernel.expects(:exec).with("#{@script} #{HOBO_MOCK_CONFIG[:ssh][:uname]}")
      Hobo::SSH.connect
    end

    test "should call exec with supplied params" do
      args = {:uname => 'bar', :pass => 'baz', :host => 'bak'}
      Kernel.expects(:exec).with("#{@script} #{args[:uname]} #{args[:pass]} #{args[:host]}")
      Hobo::SSH.connect(args)
    end
  end
end
