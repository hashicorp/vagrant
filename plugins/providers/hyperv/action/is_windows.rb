module VagrantPlugins
  module HyperV
    module Action
      class IsWindows
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          env[:result] = env[:machine].config.vm.guest == :windows
          @app.call(env)
        end
      end
    end
  end
end
