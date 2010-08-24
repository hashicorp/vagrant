require "test_helper"

class CLITest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::CLI
  end

  context "registering" do
    should "register a base command as a single invokable" do
      base = Class.new(Vagrant::Command::Base)
      name = "__test_registering_single_subcommand"
      @klass.register(base, name, name, "A description")
      assert @klass.tasks[name]
    end

    should "register a group base as a subcommand" do
      base = Class.new(Vagrant::Command::GroupBase)
      name = "_test_registering_single_group"
      @klass.register(base, name, name, "A description")
      assert @klass.subcommands.include?(name)
    end
  end
end
