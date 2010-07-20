require "test_helper"

class TranslatorUtilTest < Test::Unit::TestCase
  include Vagrant::Util

  setup do
    @klass = Translator
  end

  context "loading the errors from the YML" do
    setup do
      YAML.stubs(:load_file)
      @klass.reset!
    end

    should "load the file initially, then never again unless reset" do
      YAML.expects(:load_file).with(File.join(PROJECT_ROOT, "templates", "strings.yml")).once
      @klass.strings
      @klass.strings
      @klass.strings
      @klass.strings
    end

    should "reload if reset! is called" do
      YAML.expects(:load_file).with(File.join(PROJECT_ROOT, "templates", "strings.yml")).twice
      @klass.strings
      @klass.reset!
      @klass.strings
    end
  end

  context "getting the string translated" do
    setup do
      @strings = {}
      @strings[:foo] = "foo bar baz"
      @klass.stubs(:strings).returns(@strings)
    end

    should "render the error string" do
      TemplateRenderer.expects(:render_string).with(@strings[:foo], anything).once
      @klass.t(:foo)
    end

    should "pass in any data entries" do
      data = mock("data")
      TemplateRenderer.expects(:render_string).with(@strings[:foo], data).once
      @klass.t(:foo, data)
    end

    should "return the result of the render" do
      result = mock("result")
      TemplateRenderer.expects(:render_string).returns(result)
      assert_equal result, @klass.t(:foo)
    end

    should "return an unknown if the key doesn't exist" do
      result = @klass.t(:unknown)
      assert result =~ /Unknown/i
    end
  end
end
