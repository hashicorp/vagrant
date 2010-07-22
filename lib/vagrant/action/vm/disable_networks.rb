module Vagrant
  class Action
    module VM
      # Middleware to disable all host only networks on the
      # VM
      class DisableNetworks
        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          env.logger.info "Disabling host only networks..."

          env["vm"].vm.network_adapters.each do |adapter|
            next if adapter.attachment_type != :host_only
            adapter.enabled = false
            adapter.save
          end

          @app.call(env)
        end
      end
    end
  end
end
