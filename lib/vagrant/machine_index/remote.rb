module Vagrant
  class MachineIndex
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
      def initialize(*args)
        @logger = Log4r::Logger.new("vagrant::machine_index")
        @machines  = {}
      end

      # Deletes a machine by UUID.
      #
      # @param [Stinrg] The uuid for the entry to delete.
      # @return [Boolean] true if delete is successful
      def delete(uuid)
        @machines.delete(uuid)
        ref = Hashicorp::Vagrant::Sdk::TargetIndex::TargetIdentifier.new(
          id: uuid
        )
        @client.delete(ref)
      end

      # Accesses a machine by UUID
      #
      # @param [String] uuid for the machine to access.
      # @return [MachineIndex::Entry]
      def get(uuid)
        ref = Hashicorp::Vagrant::Sdk::TargetIndex::TargetIdentifier.new(
          id: uuid
        )
        @client.get(ref)
      end
      
      # Tests if the index has the given UUID.
      #
      # @param [String] uuid
      # @return [Boolean]
      def include?(uuid)
        ref = Hashicorp::Vagrant::Sdk::TargetIndex::TargetIdentifier.new(
          id: uuid
        )
        @client.include?(ref)
      end

      def release(entry)
        #no-op
      end

      # Creates/updates an entry object and returns the resulting entry.
      #
      # @param [Entry] entry
      # @return [Entry]
      def set(entry)
        entry_new = @client.set(entry)
        @machines[entry.id] = entry_new
      end

      def recover(entry)
        #no-op
      end

      # Iterate over every machine in the index
      def each(reload=true)
        if reload
          machines = @client.all()
          machines.each do |m|
            @machines[m.id] = m
          end
        end

        @logger.debug("machines: #{@machines.keys}")
        @machines.each do |uuid, data|
          yield data
        end
      end
    end
  end
end
