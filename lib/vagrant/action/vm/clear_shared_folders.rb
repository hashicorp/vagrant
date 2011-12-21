module Vagrant
  module Action
    module VM
      class ClearSharedFolders
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          env[:vm].driver.clear_shared_folders

          @app.call(env)
        end
      end
    end
  end
end
