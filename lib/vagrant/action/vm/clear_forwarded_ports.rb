require File.join(File.dirname(__FILE__), 'forward_ports_helpers')

module Vagrant
  class Action
    module VM
      class ClearForwardedPorts
        include ForwardPortsHelpers

        def initialize(app, env)
          @app = app
          @env = env
        end

        def call(env)
          @env = env
          clear
          @app.call(env)
        end

        def clear
          if used_ports.length > 0
            @env.logger.info "Deleting any previously set forwarded ports..."
            clear_ports
            @env["vm"].reload!
          end
        end

        # Deletes existing forwarded ports.
        def clear_ports
          @env["vm"].vm.network_adapters.each do |na|
            na.nat_driver.forwarded_ports.dup.each do |fp|
              fp.destroy
            end
          end
        end
      end
    end
  end
end
