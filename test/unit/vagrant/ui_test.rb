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

      @instance.info("vagrant.errors.test_key", :prefix => false)
    end
  end
end
