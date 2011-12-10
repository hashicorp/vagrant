module Vagrant
  module Action
    module VM
      # Destroys the unused host only interfaces. This middleware cleans
      # up any created host only networks.
      class DestroyUnusedNetworkInterfaces
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Destroy all the host only network adapters which are empty.
          VirtualBox::Global.global(true).host.network_interfaces.each do |iface|
            # We only care about host only interfaces
            next if iface.interface_type != :host_only

            # Destroy it if there is nothing attached
            if iface.attached_vms.empty?
              env[:ui].info I18n.t("vagrant.actions.vm.destroy_network.destroying")
              iface.destroy
            end
          end

          # Continue along
          @app.call(env)
        end
      end
    end
  end
end
