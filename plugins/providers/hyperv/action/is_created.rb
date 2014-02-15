#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

require "log4r"
module VagrantPlugins
  module HyperV
    module Action
      class IsCreated
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          env[:result] = env[:machine].state.id != :not_created
          @app.call(env)
        end
      end
    end
  end
end
