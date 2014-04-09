require "fileutils"

require "log4r"

module VagrantPlugins
  module HyperV
    module Action
      class CheckEnabled
        def initialize(app, env)
          @app    = app
        end

        def call(env)
          env[:ui].output("Verifying Hyper-V is enabled...")
          result = env[:machine].provider.driver.execute("check_hyperv.ps1", {})
          raise Errors::PowerShellFeaturesDisabled if !result["result"]

          @app.call(env)
        end
      end
    end
  end
end
