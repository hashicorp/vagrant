module VagrantPlugins
  module DockerProvider
    module Action
      class ForwardPorts
        def initialize(app, env)
          @app = app
        end

        def call(env)
          @env = env

          env[:forwarded_ports] = compile_forwarded_ports(env[:machine].config)

          if env[:forwarded_ports].any?
            env[:ui].info I18n.t("vagrant.actions.vm.forward_ports.forwarding")
            inform_forwarded_ports(env[:forwarded_ports])
          end

          # FIXME: Check whether the container has already been created with
          #        different exposed ports and let the user know about it

          @app.call env
        end

        def inform_forwarded_ports(ports)
          ports.each do |fp|
            message_attributes = {
              :adapter    => 'eth0',
              :guest_port => fp[:guest],
              :host_port  => fp[:host]
            }

            @env[:ui].info(I18n.t("vagrant.actions.vm.forward_ports.forwarding_entry",
                                  message_attributes))
          end
        end

        private

        def compile_forwarded_ports(config)
          mappings = {}

          config.vm.networks.each do |type, options|
            if type == :forwarded_port && options[:id] != 'ssh'
              mappings[options[:host]] = options
            end
          end

          mappings.values
        end
      end
    end
  end
end
