module VagrantPlugins
  module HyperV
    module Action
      class StopInstance
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          env[:ui].info("Stopping the machine...")
          options = { VmId: env[:machine].id }
          env[:machine].provider.driver.execute('stop_vm.ps1', options)
          @app.call(env)
        end
      end
    end
  end
end
