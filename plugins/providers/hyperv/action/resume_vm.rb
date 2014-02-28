module VagrantPlugins
  module HyperV
    module Action
      class ResumeVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info("Resuming the machine...")
          options = { VmId: env[:machine].id }
          env[:machine].provider.driver.execute("resume_vm.ps1", options)
          @app.call(env)
        end
      end
    end
  end
end
