module Vagrant
  class Action
    module VM
      class MatchMACAddress
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env.logger.info "Matching MAC addresses..."
          env["vm"].vm.network_adapters.first.mac_address = env.env.config.vm.base_mac
          env["vm"].vm.save

          @app.call(env)
        end
      end
    end
  end
end
