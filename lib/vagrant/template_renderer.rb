module Vagrant
  # This class is used to render the ERB templates in the
  # `GEM_ROOT/templates` directory.
  class TemplateRenderer < OpenStruct
    class <<self
      def render!(*args)
        renderer = new(*args)
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

    def render
      result = nil
      File.open(full_template_path, 'r') do |f|
        erb = ERB.new(f.read)
        result = erb.result(binding)
      end

      result
    end

    def full_template_path
      File.join(PROJECT_ROOT, 'templates', "#{template}.erb")
    end
  end
end