require 'ostruct'
require "pathname"

require 'erubis'

module Vagrant
  module Util
    # This class is used to render the ERB templates in the
    # `GEM_ROOT/templates` directory.
    class TemplateRenderer < OpenStruct
      class << self
        # Render a given template and return the result. This method optionally
        # takes a block which will be passed the renderer prior to rendering, which
        # allows the caller to set any view variables within the renderer itself.
        #
        # @return [String] Rendered template
        def render(*args)
          render_with(:render, *args)
        end

        # Render a given string and return the result. This method optionally
        # takes a block which will be passed the renderer prior to rendering, which
        # allows the caller to set any view variables within the renderer itself.
        #
        # @param [String] template The template data string.
        # @return [String] Rendered template
        def render_string(*args)
          render_with(:render_string, *args)
        end

        # Method used internally to DRY out the other renderers. This method
        # creates and sets up the renderer before calling a specified method on it.
        def render_with(method, template, data={})
          renderer = new(template, data)
          yield renderer if block_given?
          renderer.send(method.to_sym)
        end
      end

      def initialize(template, data = {})
        super()

        @template_root = data.delete(:template_root)
        @template_root ||= Vagrant.source_root.join("templates")
        @template_root = Pathname.new(@template_root)

        data[:template] = template
        data.each do |key, value|
          send("#{key}=", value)
        end
      end

      # Renders the template using the class intance as the binding. Because the
      # renderer inherits from `OpenStruct`, additional view variables can be
      # added like normal accessors.
      #
      # @return [String]
      def render
        old_template = template
        result = nil
        File.open(full_template_path, 'r') do |f|
          self.template = f.read
          result = render_string
        end

        result
      ensure
        self.template = old_template
      end

      # Renders a template, handling the template as a string, but otherwise
      # acting the same way as {#render}.
      #
      # @return [String]
      def render_string
        Erubis::Eruby.new(template, trim: true).result(binding)
      end

      # Returns the full path to the template, taking into accoun the gem directory
      # and adding the `.erb` extension to the end.
      #
      # @return [String]
      def full_template_path
        @template_root.join("#{template}.erb").to_s.squeeze("/")
      end
    end
  end
end
