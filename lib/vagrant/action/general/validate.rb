module Vagrant
  module Action
    module General
      # Simply validates the configuration of the current Vagrant
      # environment.
      class Validate
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env[:vm].config.validate!(@env[:vm].env) if !@env.has_key?("validate") || @env["validate"]
          @app.call(@env)
        end
      end
    end
  end
end
