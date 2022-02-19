module Vagrant
  module Plugin
    module Remote
      class Provider < V2::Provider
        class << self
          attr_reader :client
        end

        attr_accessor :client

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
          @client = opts.delete(:client)
        end

        def action(name)
          client.action(@machine.to_proto, name)
        end

        def machine_id_changed
          client.machine_id_changed(@machine.to_proto)
        end

        def ssh_info
          client.ssh_info(@machine.to_proto)
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
