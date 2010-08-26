require "test_helper"

class CommandGroupBaseTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Command::GroupBase
    @env = mock_environment
  end

  context "initialization" do
    should "require an environment" do
      assert_raises(Vagrant::CLIMissingEnvironment) { @klass.new([], {}, {}) }
      assert_nothing_raised { @klass.new([], {}, { :env => @env }) }
    end
  end
end
