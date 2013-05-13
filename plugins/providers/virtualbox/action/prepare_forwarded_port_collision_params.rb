module VagrantPlugins
  module ProviderVirtualBox
    module Action
      class PrepareForwardedPortCollisionParams
        def initialize(app, env)
          @app = app
        end

        def call(env)
          # Get the forwarded ports used by other virtual machines and
          # consider those in use as well.
          env[:port_collision_extra_in_use] = env[:machine].provider.driver.read_used_ports

          # Build the remap for any existing collision detections
          remap = {}
          env[:port_collision_remap] = remap
          env[:machine].provider.driver.read_forwarded_ports.each do |_nic, name, hostport, _guestport|
            env[:machine].config.vm.networks.each do |type, options|
              next if type != :forwarded_port

              # If the ID matches the name of the forwarded port, then
              # remap.
              if options[:id] == name
                remap[options[:host]] = hostport
                break
              end
            end
          end

          @app.call(env)
        end
      end
    end
  end
end
