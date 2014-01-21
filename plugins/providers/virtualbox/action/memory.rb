require "set"

require "log4r"


module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # This middleware class sets the memory sive for the guest.
      #
      # This handles the `config.vm.memory =` configuration.
      class Memory

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::virtualbox::memory_size")
          @app    = app
        end

        def call(env)
          # TODO: Validate network configuration prior to anything below
          @env = env
          env[:machine].provider_config.memory = env[:machine].config.vm.memory if env[:machine].config.vm.memory
          # Continue the middleware chain.
          @app.call(env)
        end
      end
    end
  end
end