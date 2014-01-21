require "set"

require "log4r"


module VagrantPlugins
  module ProviderVirtualBox
    module Action
      # This middleware class sets the number of CPUs for the guest
      #
      # This handles the `config.vm.cpus = ` configuration.
      class Cpus

        def initialize(app, env)
          @logger = Log4r::Logger.new("vagrant::plugins::virtualbox::cpus")
          @app    = app
        end

        def call(env)
          @env = env
          env[:machine].provider_config.cpus = env[:machine].config.vm.cpus if env[:machine].config.vm.cpus 
          # Continue the middleware chain.
          @app.call(env)
        end
      end
    end
  end
end