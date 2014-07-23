require 'fileutils'

require 'log4r'

module VagrantPlugins
  module HyperV
    module Action
      class CheckEnabled
        def initialize(app, _env)
          @app    = app
        end

        def call(env)
          env[:ui].output('Verifying Hyper-V is enabled...')
          result = env[:machine].provider.driver.execute('check_hyperv.ps1', {})
          fail Errors::PowerShellFeaturesDisabled unless result['result']

          @app.call(env)
        end
      end
    end
  end
end
