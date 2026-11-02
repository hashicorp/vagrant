# Copyright IBM Corp. 2010, 2025
# SPDX-License-Identifier: MIT

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
