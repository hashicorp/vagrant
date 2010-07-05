module Vagrant
  class Action
    module VM
      # Destroys the unused host only interfaces. This middleware cleans
      # up any created host only networks.
      class DestroyUnusedNetworkInterfaces
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # We need to check if the host only network specified by any
          # of the adapters would not have any more clients if it was
          # destroyed. And if so, then destroy the host only network
          # itself.
          interfaces = env["vm"].vm.network_adapters.collect do |adapter|
            adapter.host_interface_object
          end

          interfaces.compact.uniq.each do |interface|
            # Destroy the network interface if there is only one
            # attached VM (which must be this VM)
            if interface.attached_vms.length == 1
              env.logger.info "Destroying unused network interface..."
              interface.destroy
            end
          end

          # Continue along
          @app.call(env)
        end
      end
    end
  end
end
