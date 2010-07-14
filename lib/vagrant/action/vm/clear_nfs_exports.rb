require File.join(File.dirname(__FILE__), 'nfs_helpers')

module Vagrant
  class Action
    module VM
      class ClearNFSExports
        include NFSHelpers

        def initialize(app, env)
          @app = app
        end

        def call(env)
          clear_nfs_exports(env)
          @app.call(env)
        end
      end
    end
  end
end
