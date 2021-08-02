module Vagrant
  class MachineIndex
    # This module enables the MachineIndex for server mode
    module Remote

      # Add an attribute reader for the client
      # when applied to the MachineIndex class
      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      # Initializes a MachineIndex
      def initialize(*args)
        @logger = Log4r::Logger.new("vagrant::machine_index")
        @machines  = {}
      end

      def set_client(client)
        @logger.debug("setting machine index client")
        @client = client
      end

      # Deletes a machine by UUID.
      #
      # @param [Entry] entry The entry to delete.
      # @return [Boolean] true if delete is successful
      def delete(entry)
        machine = entry_to_machine(entry)
        @client.delete(machine)
      end

      # Accesses a machine by UUID
      #
      # @param [String] uuid UUID for the machine to access.
      # @return [MachineIndex::Entry]
      def get(uuid)
        @client.get(machine)
      end
      
      # Tests if the index has the given UUID.
      #
      # @param [String] uuid
      # @return [Boolean]
      def include?(uuid)
        @client.include?(uuid)
      end

      def release(entry)
        #no-op
      end

      # Creates/updates an entry object and returns the resulting entry.
      #
      # @param [Entry] entry
      # @return [Entry]
      def set(entry)
        machine_in = entry_to_machine(entry)
        machine_out = @client.set(machine_in)
        machine_to_entry(machine_out)
      end

      def recover(entry)
        #TODO
      end

      protected

      # Converts a machine index entry to a machine
      #
      # @param [Vagrant::MachineIndex::Entry] 
      # @return [Hashicorp::Vagrant::Sdk::Args::Target]
      def entry_to_machine(entry)
      end

      # Converts a machine to a machine index entry
      #
      # @param [Hashicorp::Vagrant::Sdk::Args::Target]
      # @return [Vagrant::MachineIndex::Entry] 
      def machine_to_entry(machine)
      end
    end
  end
end
