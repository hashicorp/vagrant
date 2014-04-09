
require "log4r"

module VagrantPlugins
  module HyperV
    module Action
      class ReadState
        def initialize(app, env)
          @app    = app
          @logger = Log4r::Logger.new("vagrant::hyperv::connection")
        end

        def call(env)
          if env[:machine].id
            response = env[:machine].provider.driver.get_current_state
            env[:machine_state_id] = response["state"].downcase.to_sym

            # If the machine isn't created, then our ID is stale, so just
            # mark it as not created.
            if env[:machine_state_id] == :not_created
              env[:machine].id = nil
            end
          else
            env[:machine_state_id] = :not_created
          end
          @app.call(env)
        end
      end
    end
  end
end
