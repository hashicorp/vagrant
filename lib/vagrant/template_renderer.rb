module Vagrant
  # This class is used to render the ERB templates in the
  # `GEM_ROOT/templates` directory.
  class TemplateRenderer < OpenStruct
    class <<self
      # Render a given template and return the result. This method optionally
      # takes a block which will be passed the renderer prior to rendering, which
      # allows the caller to set any view variables within the renderer itself.
      #
      # @param [String] template Name of the template file, without the extension
      # @return [String] Rendered template
      def render!(template, data={})
        renderer = new(template, data)
        yield renderer if block_given?
        renderer.render
      end
    end

    def initialize(template, data = {})
      super()

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
      result = nil
      File.open(full_template_path, 'r') do |f|
        erb = ERB.new(f.read)
        result = erb.result(binding)
      end

      result
    end

    # Returns the full path to the template, taking into accoun the gem directory
    # and adding the `.erb` extension to the end.
    #
    # @return [String]
    def full_template_path
      File.join(PROJECT_ROOT, 'templates', "#{template}.erb")
    end
  end
end