require File.join(File.dirname(__FILE__), '..', 'test_helper')

class SshTest < Test::Unit::TestCase
  setup do
    @session = mock("session")

    @klass = Vagrant::SSH::Session
    @instance = @klass.new(@session)
  end

  context "checking exit status" do
    should "raise an ActionException if its non-zero" do
      assert_raises(Vagrant::Actions::ActionException) {
        @instance.check_exit_status(1, "foo")
      }
    end

    should "raise nothing if its zero" do
      assert_nothing_raised {
        @instance.check_exit_status(0, "foo")
      }
    end
  end
end
