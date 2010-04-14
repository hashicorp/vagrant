require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class CommandsDownTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Commands::Down

    @env = mock_environment
    @instance = @klass.new(@env)
  end

  context "executing" do
    should "just error and exit" do
      @instance.expects(:error_and_exit).with(:command_deprecation_down)
      @instance.execute
    end
  end
end
