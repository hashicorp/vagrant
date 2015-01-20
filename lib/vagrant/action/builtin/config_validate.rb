require "vagrant/util/template_renderer"

module Vagrant
  module Action
    module Builtin
      # This class validates the configuration and raises an exception
      # if there are any validation errors.
      class ConfigValidate
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if !env.key?(:config_validate) || env[:config_validate]
            errors = env[:machine].config.validate(env[:machine])

            if errors && !errors.empty?
              raise Errors::ConfigInvalid,
                errors: Util::TemplateRenderer.render(
                  "config/validation_failed",
                  errors: errors)
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
