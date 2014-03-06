module VagrantPlugins
  module HyperV
    module Action
      class DeleteVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info("Deleting the machine...")
          env[:machine].provider.driver.delete_vm
          @app.call(env)
        end
      end
    end
  end
end
