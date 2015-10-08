require "log4r"

module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PrepareClone
        def initialize(app, env)
          @app = app
          @logger = Log4r::Logger.new("vagrant::action::vm::prepare_clone")
        end

        def call(env)
          # We need to get the machine ID from this Vagrant environment

          # Continue
          @app.call(env)
        end
      end
    end
  end
end
