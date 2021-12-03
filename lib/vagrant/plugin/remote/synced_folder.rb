module Vagrant
  module Plugin
    module Remote
      class SyncedFolder
        # This module enables SyncedFolder for server mode
        module Remote

          # Add an attribute accesor for the client
          # when applied to the SyncedFolder class
          def self.prepended(klass)
            klass.class_eval do
              attr_accessor :client
            end
          end

          def initialize(client=nil)
            @client = client
            if @client.nil?
              raise ArgumentError,
                "Remote client is required for `#{self.class.name}'"
            end
            @logger = Log4r::Logger.new("vagrant::remote::synced_folder")
          end
          
          def _initialize(machine, synced_folder_type, client=nil)
            self
          end

          def initialize_capabilities!(host, hosts, capabilities, *args)
            # no-op
          end

          # @param [Machine] machine
          # @param [Boolean] raise_error If true, should raise an exception
          #   if it isn't usable.
          # @return [Boolean]
          def usable?(machine, raise_error=false)
            begin
              client.usable(machine.to_proto)
            rescue
              raise if raise_error
            end
          end

          # @param [Machine] machine
          # @param [Hash] folders The folders to remove. This will not contain
          #   any folders that should remain.
          # @param [Hash] opts Any options for the synced folders.
          def enable(machine, folders, opts)
            client.enable(machine.to_proto, folders, opts)
          end

          # @param [Machine] machine The machine to modify.
          # @param [Hash] folders The folders to remove. This will not contain
          #   any folders that should remain.
          # @param [Hash] opts Any options for the synced folders.
          def disable(machine, folders, opts)
            client.disable(machine.to_proto, folders, opts)
          end

          # @param [Machine] machine
          # @param [Hash] opts
          def cleanup(machine, opts)
            client.cleanup(machine.to_proto, opts)
          end

          # Executes the capability with the given name, optionally passing more
          # arguments onwards to the capability. If the capability returns a value,
          # it will be returned.
          #
          # @param [Symbol] cap_name Name of the capability
          def capability(cap_name, *args)
            @logger.debug("running remote synced folder capability #{cap_name} with args #{args}")
            client.capability(cap_name, *args)
          end

          # Tests whether the given capability is possible.
          #
          # @param [Symbol] cap_name Capability name
          # @return [Boolean]
          def capability?(cap_name)
            @logger.debug("checking for remote synced folder capability #{cap_name}")
            client.has_capability?(cap_name)
          end

          def to_proto
            client.proto
          end
        end
      end
    end
  end
end
