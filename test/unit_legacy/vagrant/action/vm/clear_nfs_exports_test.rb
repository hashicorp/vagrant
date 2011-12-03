require "test_helper"

class ClearNFSExportsActionTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Action::VM::ClearNFSExports
    @app, @env = action_env
    @env.env.stubs(:host).returns(Vagrant::Hosts::Base.new(@env))

    @instance = @klass.new(@app, @env)
  end

  should "include the NFS helpers module" do
    assert @klass.included_modules.include?(Vagrant::Action::VM::NFSHelpers)
  end

  should "clear NFS exports then continue chain" do
    seq = sequence("seq")
    @instance.expects(:clear_nfs_exports).with(@env).in_sequence(seq)
    @app.expects(:call).with(@env).in_sequence(seq)
    @instance.call(@env)
  end
end
