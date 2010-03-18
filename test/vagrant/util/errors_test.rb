require File.join(File.dirname(__FILE__), '..', '..', 'test_helper')

class ErrorsUtilTest < Test::Unit::TestCase
  include Vagrant::Util

  context "loading the errors from the YML" do
    setup do
      YAML.stubs(:load_file)
      Errors.reset!
    end

    should "load the file initially, then never again unless reset" do
      YAML.expects(:load_file).with(File.join(PROJECT_ROOT, "templates", "errors.yml")).once
      Errors.errors
      Errors.errors
      Errors.errors
      Errors.errors
    end

    should "reload if reset! is called" do
      YAML.expects(:load_file).with(File.join(PROJECT_ROOT, "templates", "errors.yml")).twice
      Errors.errors
      Errors.reset!
      Errors.errors
    end
  end

  context "getting the error string" do
    setup do
      @errors = {}
      @errors[:foo] = "foo bar baz"
      Errors.stubs(:errors).returns(@errors)
    end

    should "render the error string" do
      TemplateRenderer.expects(:render_string).with(@errors[:foo], anything).once
      Errors.error_string(:foo)
    end

    should "pass in any data entries" do
      data = mock("data")
      TemplateRenderer.expects(:render_string).with(@errors[:foo], data).once
      Errors.error_string(:foo, data)
    end

    should "return the result of the render" do
      result = mock("result")
      TemplateRenderer.expects(:render_string).returns(result)
      assert_equal result, Errors.error_string(:foo)
    end
  end
end
