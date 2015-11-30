module Vagrant
  module Action
    module Builtin
      # This middleware is meant to be used with Call and can check if
      # a variable in env is set.
      class IsEnvSet
        def initialize(app, env, key, **opts)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::action::builtin::is_env_set")
          @key    = key
        end

        def call(env)
          @logger.debug("Checking if env is set: '#{@key}'")
          env[:result] = !!env[@key]
          @logger.debug(" - Result: #{env[:result].inspect}")
          @app.call(env)
        end
      end
    end
  end
end
