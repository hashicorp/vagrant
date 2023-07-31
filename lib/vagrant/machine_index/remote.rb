# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  class MachineIndex
    class Entry
      module Remote
        module ClassMethods
          def load(machine)
            raw = Vagrant::Util::HashWithIndifferentAccess.new({
              name: machine.name,
              local_data_path: machine.project.local_data,
              provider: machine.provider_name,
              full_state: machine.machine_state,
              state: machine.machine_state.id,
              vagrantfile_name: machine.project.vagrantfile_name,
              vagrantfile_path: machine.project.vagrantfile_path,
              machine: machine
            })
            self.new(machine.id, raw)
          end
        end

        module InstanceMethods
          def initialize(id, raw=nil)
            @logger = Log4r::Logger.new("vagrant::machine_index::entry")

            @extra_data = {}
            @id = id
            # Do nothing if we aren't given a raw value. Otherwise, parse it.
            return if !raw

            @local_data_path  = raw["local_data_path"]
            @name             = raw["name"]
            @provider         = raw["provider"]
            @state            = raw["state"]
            @full_state       = raw["full_state"]
            @vagrantfile_name = raw["vagrantfile_name"]
            @vagrantfile_path = raw["vagrantfile_path"]
            # TODO(mitchellh): parse into a proper datetime
            @updated_at       = raw["updated_at"]
            @extra_data       = raw["extra_data"] || {}

            @machine_client = raw["machine"]

            # Be careful with the paths
            @local_data_path = nil  if @local_data_path == ""
            @vagrantfile_path = nil if @vagrantfile_path == ""

            # Convert to proper types
            @local_data_path = Pathname.new(@local_data_path) if @local_data_path
            @vagrantfile_path = Pathname.new(@vagrantfile_path) if @vagrantfile_path
          end

          def vagrant_env(home_path, opts={})
            Vagrant::Util::SilenceWarnings.silence! do
              Environment.new({
                cwd: @vagrantfile_path,
                home_path: home_path,
                local_data_path: @local_data_path,
                vagrantfile_name: @vagrantfile_name,
                client: @machine_client&.project,
              }.merge(opts))
            end
          end

          def valid?(home_path)
            # Always return true
            true
          end
        end
      end
    end

    # This module enables the MachineIndex for server mode
    module Remote

      attr_accessor :client

      # Add an attribute reader for the client
      # when applied to the MachineIndex class
      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      # Initializes a MachineIndex
      def initialize(*args, **opts)
        @logger = Log4r::Logger.new("vagrant::machine_index")
        @client = opts[:client]
        if @client.nil?
          raise ArgumentError,
            "Remote client is required for `#{self.class.name}'"
        end
        @machines = {}
      end

      # Deletes a machine by identifier.
      #
      # @param [String] uuid Target identifier
      # @return [Boolean] true if delete is successful
      def delete(uuid)
        @machines.delete(uuid)
        client.delete(uuid)
      end

      # Accesses a machine by identifier.
      #
      # @param [String] uuid Target identifier
      # @return [MachineIndex::Entry]
      def get(uuid)
        client.get(uuid)
      end

      # Tests if the index has the given identifier.
      #
      # @param [String] ident Target identifier
      # @return [Boolean]
      def include?(uuid)
        client.include?(uuid)
      end

      def release(*_)
        #no-op
      end

      # Creates/updates an entry object and returns the resulting entry.
      #
      # @param [Entry] entry
      # @return [Entry]
      def set(entry)
        entry_new = client.set(entry)
        @machines[entry.id] = entry_new
      end

      def recover(entry)
        #no-op
      end

      # Iterate over every machine in the index
      def each(reload=true, &block)
        if reload
          client.all.each do |m|
            @machines[m.id] = m
          end
        end

        @logger.debug("machines: #{@machines.keys}")
        @machines.each_value(&block)
      end

      def to_proto
        client.proto
      end
    end
  end
end
