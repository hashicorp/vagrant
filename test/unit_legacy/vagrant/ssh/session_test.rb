require "test_helper"

class SshSessionTest < Test::Unit::TestCase
  setup do
    @session = mock("session")
    @env = vagrant_env

    @klass = Vagrant::SSH::Session
    @instance = @klass.new(@session, @env)
  end

  context "exec!" do
    should "retry max_tries times" do
      @session.expects(:open_channel).times(@env.config.ssh.max_tries).raises(IOError)
      assert_raises(IOError) {
        @instance.exec!("foo")
      }
    end
  end

  context "checking exit status" do
    should "raise an ActionException if its non-zero" do
      assert_raises(Vagrant::Errors::VagrantError) {
        @instance.check_exit_status(1, "foo")
      }
    end

    should "raise the given exception if specified" do
      assert_raises(Vagrant::Errors::BaseVMNotFound) {
        @instance.check_exit_status(1, "foo", :_error_class => Vagrant::Errors::BaseVMNotFound)
      }
    end

    should "raise nothing if its zero" do
      assert_nothing_raised {
        @instance.check_exit_status(0, "foo")
      }
    end
  end
end
