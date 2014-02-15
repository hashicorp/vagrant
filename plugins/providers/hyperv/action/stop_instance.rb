#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------

require "log4r"
module VagrantPlugins
  module HyperV
    module Action
        class StopInstance
            def initialize(app, env)
              @app    = app
            end

            def call(env)
                env[:ui].info('Stopping the Machine')
                options = { vm_id: env[:machine].id }
                response = env[:machine].provider.driver.execute('stop_vm.ps1', options)
                @app.call(env)
            end
        end
    end
  end
end
