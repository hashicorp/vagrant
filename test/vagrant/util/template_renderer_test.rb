require "test_helper"

class TemplateRendererUtilTest < Test::Unit::TestCase
  context "initializing" do
    should "set the template to the given argument" do
      r = Vagrant::Util::TemplateRenderer.new("foo")
      assert_equal "foo", r.template
    end

    should "set any additional variables" do
      r = Vagrant::Util::TemplateRenderer.new("foo", {:bar => :baz})
      assert_equal :baz, r.bar
    end
  end

  context "rendering" do
    setup do
      @template = "foo"
      @r = Vagrant::Util::TemplateRenderer.new(@template)
      @r.stubs(:full_template_path).returns(@template + "!")

      @contents = "bar"

      @file = mock("file")
      @file.stubs(:read).returns(@contents)
      File.stubs(:open).yields(@file)
    end

    should "open the template file for reading" do
      File.expects(:open).with(@r.full_template_path, 'r').once
      @r.render
    end

    should "set the template to the file contents, render, then set it back" do
      result = "bar"

      template_seq = sequence("template_seq")
      @r.expects(:template=).with(@file.read).in_sequence(template_seq)
      @r.expects(:render_string).returns(result).in_sequence(template_seq)
      @r.expects(:template=).with(@template).in_sequence(template_seq)
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

  context "rendering as string" do
    setup do
      @result = "foo"
      @erb = mock("erb")
      @erb.stubs(:result).returns(@result)

      @r = Vagrant::Util::TemplateRenderer.new("foo")
    end

    should "simply render the template as a string" do
      Erubis::Eruby.expects(:new).with(@r.template, :trim => true).returns(@erb)
      @erb.expects(:result).returns(@result)
      assert_equal @result, @r.render_string
    end
  end

  context "the full template path" do
    setup do
      @template = "foo"
      @r = Vagrant::Util::TemplateRenderer.new(@template)
    end

    should "be the ERB file in the templates directory" do
      result = Vagrant.source_root.join("templates", "#{@template}.erb")
      assert_equal result.to_s, @r.full_template_path
    end

    should "remove duplicate path separators" do
      @r.template = "foo///bar"
      result = Vagrant.source_root.join("templates", "foo", "bar.erb")
      assert_equal result.to_s, @r.full_template_path
    end
  end

  context "class methods" do
    context "render_with method" do
      setup do
        @template = "foo"
        @r = Vagrant::Util::TemplateRenderer.new(@template)
        @r.stubs(:render)

        @method = :rawr

        Vagrant::Util::TemplateRenderer.stubs(:new).with(@template, {}).returns(@r)
      end

      should "use the second argument as the template" do
        Vagrant::Util::TemplateRenderer.expects(:new).with(@template, {}).returns(@r)
        Vagrant::Util::TemplateRenderer.render_with(@method, @template)
      end

      should "send in additional argument to the renderer" do
        data = {:hey => :foo}
        Vagrant::Util::TemplateRenderer.expects(:new).with(@template, data).returns(@r)
        Vagrant::Util::TemplateRenderer.render_with(@method, @template, data)
      end

      should "yield a block if given with the renderer as the argument" do
        @r.expects(:yielded=).with(true).once
        Vagrant::Util::TemplateRenderer.render_with(@method, @template) do |r|
          r.yielded = true
        end
      end

      should "render the result using the given method" do
        result = mock('result')
        @r.expects(@method).returns(result)
        assert_equal result, Vagrant::Util::TemplateRenderer.render_with(@method, @template)
      end

      should "convert the given method to a sym prior to calling" do
        @r.expects(@method.to_sym).returns(nil)
        Vagrant::Util::TemplateRenderer.render_with(@method.to_s, @template)
      end
    end

    context "render method" do
      should "call render_with the render! method" do
        args = ["foo", "bar", "baz"]
        Vagrant::Util::TemplateRenderer.expects(:render_with).with(:render, *args)
        Vagrant::Util::TemplateRenderer.render(*args)
      end
    end

    context "render_string method" do
      should "call render_with the render! method" do
        args = ["foo", "bar", "baz"]
        Vagrant::Util::TemplateRenderer.expects(:render_with).with(:render_string, *args)
        Vagrant::Util::TemplateRenderer.render_string(*args)
      end
    end
  end
end
