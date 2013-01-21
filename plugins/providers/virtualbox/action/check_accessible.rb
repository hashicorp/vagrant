module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class CheckAccessible
        def initialize(app, env)
          @app = app
        end

        def call(env)
          if env[:machine].state.id == :inaccessible
            # The VM we are attempting to manipulate is inaccessible. This
            # is a very bad situation and can only be fixed by the user. It
            # also prohibits us from actually doing anything with the virtual
            # machine, so we raise an error.
            raise Vagrant::Errors::VMInaccessible
          end

          @app.call(env)
        end
      end
    end
  end
end
