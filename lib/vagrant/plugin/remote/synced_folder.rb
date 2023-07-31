# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Plugin
    module Remote
      class SyncedFolder < V2::SyncedFolder
        # Add an attribute accesor for the client
        # when applied to the SyncedFolder class
        attr_accessor :client

        def initialize(client: nil)
          if client.nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}`"
          end
          @client = client
          @logger = Log4r::Logger.new("vagrant::remote::synced_folder::#{self.class.name}")
          if client.nil?
            @logger.warn("synced folder remote client is unset")
          end
        end

        def _initialize(machine, synced_folder_type, client=nil)
          if client.nil? && Manager.client
            @client = Manager.client.get_plugin(
              name: synced_folder_type,
              type: :synced_folder,
            )
          else
            raise "Cannot set remote client for synced folder, no manager available"
          end

          self
        end

        def initialize_capabilities!(host, hosts, capabilities, *args)
          # no-op
        end

        # @param [Machine] machine
        # @param [Hash] folders The folders to remove. This will not contain
        #   any folders that should remain.
        # @param [Hash] opts Any options for the synced folders.
        def prepare(machine, folders, opts)
          client.prepare(machine, folders, opts)
        end

        # @param [Machine] machine
        # @param [Boolean] raise_error If true, should raise an exception
        #   if it isn't usable.
        # @return [Boolean]
        def usable?(machine, raise_error=false)
          begin
            client.usable(machine)
          rescue
            raise if raise_error
          end
        end

        # @param [Machine] machine
        # @param [Hash] folders Folders to remove
        # @param [Hash] opts Any options for the synced folders.
        def enable(machine, folders, opts)
          client.enable(machine, folders, opts)
        end

        # @param [Machine] machine The machine to modify.
        # @param [Hash] folders The folders to remove. This will not contain
        #   any folders that should remain.
        # @param [Hash] opts Any options for the synced folders.
        def disable(machine, folders, opts)
          client.disable(machine, folders, opts)
        end

        # @param [Machine] machine
        # @param [Hash] opts
        def cleanup(machine, opts)
          client.cleanup(machine, opts)
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
