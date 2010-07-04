module Vagrant
  class Action
    module VM
      class Import
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @app.call(env)
          p env['vm']
        end
      end
    end
  end
end
