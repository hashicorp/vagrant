module VagrantPlugins
  module HyperV
    module Action
      class StartInstance
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].output('Starting the machine...')
          options = { vm_id: env[:machine].id }
          env[:machine].provider.driver.execute('start_vm.ps1', options)

          @app.call(env)
        end
      end
    end
  end
end
