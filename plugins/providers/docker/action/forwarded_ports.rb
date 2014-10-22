module VagrantPlugins
  module DockerProvider
    module Action
      class ForwardedPorts
        def initialize(app, env)
          @app = app
        end

        def call(env)
          env[:machine].provider_config.ports.each do |p|
            host_ip = nil
            protocol = "tcp"
            host, guest = p.split(":", 2)
            if guest.include?(":")
              host_ip = host
              host, guest = guest.split(":", 2)
            end

            guest, protocol = guest.split("/", 2) if guest.include?("/")
            env[:machine].config.vm.network "forwarded_port",
              host: host.to_i, guest: guest.to_i,
              host_ip: host_ip,
              protocol: protocol
          end

          @app.call(env)
        end
      end
    end
  end
end
