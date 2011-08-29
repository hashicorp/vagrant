require "test_helper"

class CommandBaseTest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::Command::Base
    @env = vagrant_env
  end

  context "initialization" do
    should "require an environment" do
      assert_raises(Vagrant::Errors::CLIMissingEnvironment) { @klass.new([], {}, {}) }
      assert_nothing_raised { @klass.new([], {}, { :env => @env }) }
    end
  end

  context "extracting a name from a usage string" do
    should "extract properly" do
      assert_equal "init", @klass.extract_name_from_usage("init")
      assert_equal "init", @klass.extract_name_from_usage("init [foo] [bar]")
      assert_equal "ssh-config", @klass.extract_name_from_usage("ssh-config")
    end
  end
end
