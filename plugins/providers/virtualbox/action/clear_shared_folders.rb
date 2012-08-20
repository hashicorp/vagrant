module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class ClearSharedFolders
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:machine].provider.driver.clear_shared_folders

          @app.call(env)
        end
      end
    end
  end
end
