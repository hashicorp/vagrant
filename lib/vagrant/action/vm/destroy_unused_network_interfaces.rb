module Vagrant
  module Action
    module VM
      # Destroys the unused host only interfaces. This middleware cleans
      # up any created host only networks.
      class DestroyUnusedNetworkInterfaces
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:vm].driver.delete_unused_host_only_networks

          # Continue along
          @app.call(env)
        end
      end
    end
  end
end
