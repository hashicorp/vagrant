require File.join(File.dirname(__FILE__), '..', '..', '..', 'test_helper')

class AddBoxActionTest < Test::Unit::TestCase
  setup do
    @runner, @vm, @action = mock_action(Vagrant::Actions::Box::Add)
    mock_config
  end

  context "sub-actions" do
    setup do
      @default_order = [Vagrant::Actions::Box::Download, Vagrant::Actions::Box::Unpackage]
    end

    def setup_action_expectations
      default_seq = sequence("default_seq")
      @default_order.each do |action|
        @runner.expects(:add_action).with(action).once.in_sequence(default_seq)
      end
    end

    should "do the proper actions by default" do
      setup_action_expectations
      @action.prepare
    end
  end
end
