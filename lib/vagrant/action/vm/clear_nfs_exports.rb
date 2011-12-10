require File.expand_path("../nfs_helpers", __FILE__)

module Vagrant
  module Action
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
