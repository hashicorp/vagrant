module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # Checks that VirtualBox is installed and ready to be used.
      class CheckVirtualbox
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # This verifies that VirtualBox is installed and the driver is
          # ready to function. If not, then an exception will be raised
          # which will break us out of execution of the middleware sequence.
          Driver::Meta.new.verify!

          # Carry on.
          @app.call(env)
        end
      end
    end
  end
end
