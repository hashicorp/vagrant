module Vagrant
  module Action
    module General
      # Checks that virtualbox is installed and ready to be used.
      class CheckVirtualbox
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:vm].driver.verify!
          @app.call(env)
        end
      end
    end
  end
end
