module Vagrant
  module Plugin
    module Remote
      class Provider
        # This module enables Provider for server mode
        module Remote

          # Add an attribute accesor for the client
          # when applied to the Provider class
          def self.prepended(klass)
            klass.class_eval do
              attr_accessor :client
            end
          end

          def self.usable?(raise_error=false)
            client.usable?
          end

          def self.installed?
            client.installed?
          end

          def initialize(machine, **opts)
            @logger = Log4r::Logger.new("vagrant::remote::provider")
            @logger.debug("initializing provider with remote backend")
            @machine = machine
            if opts[:client].nil?
              raise ArgumentError,
                "Remote client is required for `#{self.class.name}`"
            end
            @client = opts[:client]
            super(machine)
          end

          def action(name)
            client.action(name)
          end

          def machine_id_changed
            client.machine_id_changed
          end

          def ssh_info
            client.ssh_info
          end

          def state
            client.state(@machine.to_proto)
          end

          def initialize_capabilities!(*args, **opts)
            # no-op
          end

          def to_proto
            client.proto
          end
        end
      end
    end
  end
end
