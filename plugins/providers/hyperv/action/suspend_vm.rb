module VagrantPlugins
  module HyperV
    module Action
      class SuspendVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info("Suspending the machine...")
          options = { VmId: env[:machine].id }
          env[:machine].provider.driver.execute("suspend_vm.ps1", options)
          @app.call(env)
        end
      end
    end
  end
end
