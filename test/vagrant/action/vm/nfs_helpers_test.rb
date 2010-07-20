require "test_helper"

class NFSHelpersVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Class.new
    @klass.send(:include, Vagrant::Action::VM::NFSHelpers)
    @app, @env = mock_action_data

    @instance = @klass.new
  end

  should "clear NFS exports for the environment if the host exists" do
    @host = mock("host")
    @env.env.stubs(:host).returns(@host)
    @host.expects(:nfs_cleanup).once

    @instance.clear_nfs_exports(@env)
  end

  should "not do anything if host is nil" do
    assert_nothing_raised { @instance.clear_nfs_exports(@env) }
  end
end
