module Vagrant
  class MachineIndex
    class Entry
      module Remote
        def load(machine)
          self.new(machine.id, {
            name: machine.name,
            local_data_path: machine.project.local_data_path,
            provider: machine.provider_name,
            full_state: machine.machine_state,
            state: machine.machine_state.id,
            vagrantfile_name: machine.project.vagrantfile_name,
            vagrantfile_path: machine.project.vagrantfile_path,
          })
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
    end
  end
end
