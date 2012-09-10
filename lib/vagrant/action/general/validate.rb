module Vagrant
  module Action
    module General
      # Simply validates the configuration of the current Vagrant
      # environment.
      class Validate
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if !env.has_key?(:validate) || env[:validate]
            env[:machine].config.validate!(env[:machine].env)
          end

          @app.call(env)
        end
      end
    end
  end
end
