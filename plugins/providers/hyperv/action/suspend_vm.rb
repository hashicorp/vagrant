# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

module VagrantPlugins
  module HyperV
    module Action
      class SuspendVM
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:ui].info("Suspending the machine...")
          env[:machine].provider.driver.suspend
          @app.call(env)
        end
      end
    end
  end
end
