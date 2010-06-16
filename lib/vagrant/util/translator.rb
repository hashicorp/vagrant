require 'yaml'

module Vagrant
  module Util
    # This class is responsible for reading static messages from the strings.yml file.
    class Translator
      @@strings = nil

      class << self
        # Resets the internal strings hash to nil, forcing a reload on the next
        # access of {strings}.
        def reset!
          @@strings = nil
        end

        # Returns the hash of strings from the error YML files. This only loads once,
        # then returns a cached value until {reset!} is called.
        #
        # @return [Hash]
        def strings
          @@strings ||= YAML.load_file(File.join(PROJECT_ROOT, "templates", "strings.yml"))
        end

        # Renders the string with the given key and data parameters and returns
        # the rendered result.
        #
        # @return [String]
        def t(key, data = {})
          template = strings[key] || "Unknown strings key: #{key}"
          TemplateRenderer.render_string(template, data)
        end
      end
    end
  end
end
