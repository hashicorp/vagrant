module Vagrant
  module Plugin
    module V2
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

          def _initialize(machine, synced_folder_type)
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
        end
      end
    end
  end
end
