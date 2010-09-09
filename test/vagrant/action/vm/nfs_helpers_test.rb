require "test_helper"

class NFSHelpersVMActionTest < Test::Unit::TestCase
  setup do
    @klass = Class.new do
      include Vagrant::Action::VM::NFSHelpers
    end

    @app, @env = action_env

    @instance = @klass.new
  end

  should "clear NFS exports for the environment if the host exists" do
    @host = mock("host")
    @env.env.stubs(:host).returns(@host)
    @host.expects(:nfs_cleanup).once

    @instance.clear_nfs_exports(@env)
  end

  should "not do anything if host is nil" do
    @env.env.stubs(:host).returns(nil)
    assert_nothing_raised { @instance.clear_nfs_exports(@env) }
  end
end
