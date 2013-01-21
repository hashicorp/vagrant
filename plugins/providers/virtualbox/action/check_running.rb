module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # This middleware checks that the VM is running, and raises an exception
      # if it is not, notifying the user that the VM must be running.
      class CheckRunning
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].state.id != :running
            raise Vagrant::Errors::VMNotRunningError
          end

          @app.call(env)
        end
      end
    end
  end
end
