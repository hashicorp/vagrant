#-------------------------------------------------------------------------
# Copyright (c) Microsoft Open Technologies, Inc.
# All Rights Reserved. Licensed under the MIT License.
#--------------------------------------------------------------------------
require "log4r"
require "timeout"
require "debugger"

module VagrantPlugins
  module HyperV
    module Action
      class WaitForState
        def initialize(app, env, state, timeout)
          @app     = app
          @state   = state
          @timeout = timeout
        end

        def call(env)
          env[:result] = true
          # Wait until the Machine's state is disabled (ie State of Halt)
          unless env[:machine].state.id == @state
            env[:ui].info("Waiting for machine to #{@state}")
            begin
              Timeout.timeout(@timeout) do
                until env[:machine].state.id == @state
                  sleep 2
                end
              end
            rescue Timeout::Error
              env[:result] = false # couldn't reach state in time
            end
          end
          @app.call(env)
        end

      end
    end
  end
end
