require File.expand_path("../forward_ports_helpers", __FILE__)

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
            @env.ui.info "vagrant.actions.vm.clear_forward_ports.deleting"
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
