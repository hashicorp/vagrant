module VagrantPlugins
  module HyperV
    module Action
      class DeleteVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info('Deleting the Machine')
          options = { VmId: env[:machine].id }
          env[:machine].provider.driver.execute('delete_vm.ps1', options)
          @app.call(env)
        end
      end
    end
  end
end
