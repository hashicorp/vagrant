require "test_helper"

class ShellUITest < Test::Unit::TestCase
  setup do
    @klass = Vagrant::UI::Shell
    @shell = mock("shell")
    @instance = @klass.new(vagrant_env, @shell)
  end

  context "prefixing with resource" do
    should "prefix message with environment resource" do
      @shell.expects(:say).with() do |message, color|
        assert message =~ /\[#{@instance.env.resource}\]/
        true
      end

      @instance.info("vagrant.errors.test_key")
    end

    should "not prefix the message if given false" do
      @shell.expects(:say).with() do |message, color|
        assert message !~ /\[#{@instance.env.resource}\]/
        true
      end

      @instance.info("vagrant.errors.test_key", :_prefix => false)
    end
  end

  context "translating" do
    should "translate the message by default" do
      @shell.expects(:say).with() do |message, color|
        assert message.include?(I18n.t("vagrant.errors.test_key"))
        true
      end

      @instance.info("vagrant.errors.test_key")
    end

    should "not translate the message if noted" do
      @shell.expects(:say).with() do |message, color|
        assert message.include?("vagrant.errors.test_key")
        true
      end

      @instance.info("vagrant.errors.test_key", :_translate => false)
    end
  end
end
