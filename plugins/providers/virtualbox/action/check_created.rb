module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # This middleware checks that the VM is created, and raises an exception
      # if it is not, notifying the user that creation is required.
      class CheckCreated
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].state.id == :not_created
            raise Vagrant::Errors::VMNotCreatedError
          end

          @app.call(env)
        end
      end
    end
  end
end
