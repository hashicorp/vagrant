require File.join(File.dirname(__FILE__), '..', 'test_helper')

class TemplateRendererTest < Test::Unit::TestCase
  context "initializing" do
    should "set the template to the given argument" do
      r = Vagrant::TemplateRenderer.new("foo")
      assert_equal "foo", r.template
    end

    should "set any additional variables" do
      r = Vagrant::TemplateRenderer.new("foo", {:bar => :baz})
      assert_equal :baz, r.bar
    end
  end

  context "rendering" do
    setup do
      @template = "foo"
      @r = Vagrant::TemplateRenderer.new(@template)
      @r.stubs(:full_template_path).returns(@template + "!")

      @contents = "bar"

      @file = mock("file")
      @file.stubs(:read).returns(@contents)
      File.stubs(:open).yields(@file)

      @erb = mock("erb")
      @erb.stubs(:result)
    end

    should "open the template file for reading" do
      File.expects(:open).with(@r.full_template_path, 'r').once
      @r.render
    end

    should "create an ERB object with the file contents" do
      ERB.expects(:new).with(@file.read).returns(@erb)
      @r.render
    end

    should "render the ERB file and return the results" do
      result = mock("result")
      ERB.expects(:new).returns(@erb)
      @erb.expects(:result).with(anything).once.returns(result)
      assert_equal result, @r.render
    end

    should "render the ERB file in the context of the renderer" do
      result = "bar"
      template = "<%= foo %>"
      @r.foo = result
      @file.expects(:read).returns(template)
      assert_equal result, @r.render
    end
  end

  context "the full template path" do
    setup do
      @template = "foo"
      @r = Vagrant::TemplateRenderer.new(@template)
    end

    should "be the ERB file in the templates directory" do
      result = File.join(PROJECT_ROOT, "templates", "#{@template}.erb")
      assert_equal result, @r.full_template_path
    end
  end

  context "class-level render! method" do
    setup do
      @template = "foo"
      @r = Vagrant::TemplateRenderer.new(@template)
      @r.stubs(:render)

      Vagrant::TemplateRenderer.stubs(:new).with(@template, {}).returns(@r)
    end

    should "use the first argument as the template" do
      template = "foo"
      Vagrant::TemplateRenderer.expects(:new).with(template, {}).returns(@r)
      Vagrant::TemplateRenderer.render!(template)
    end

    should "send in additional argument to the renderer" do
      template = "foo"
      data = {:hey => :foo}
      Vagrant::TemplateRenderer.expects(:new).with(template, data).returns(@r)
      Vagrant::TemplateRenderer.render!(template, data)
    end

    should "yield a block if given with the renderer as the argument" do
      @r.expects(:yielded=).with(true).once
      Vagrant::TemplateRenderer.render!(@template) do |r|
        r.yielded = true
      end
    end

    should "render the result" do
      result = mock('result')
      @r.expects(:render).returns(result)
      assert_equal result, Vagrant::TemplateRenderer.render!(@template)
    end
  end
end
