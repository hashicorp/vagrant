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

    should "alias methods if the alias option is given" do
      base = Class.new(Vagrant::Command::Base) do
        def execute
          raise "WORKED"
        end
      end

      name = "__test_registering_with_alias"
      @klass.register(base, name, name, "A description", :alias => "--ALIAS")
      assert_raises(RuntimeError) { @klass.start(["--ALIAS"], :env => vagrant_env) }
    end
  end
end
