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
        get_response = @client.get(ref)
        entry = machine_to_entry(get_response)
        entry
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
        @machines[entry.id] = entry
        entry.machine_client.save
        entry
      end

      def recover(entry)
        #no-op
      end

      # Iterate over every machine in the index
      def each(reload=true)
        if reload
          arg_machines = @client.all()
          @logger.debug("machines args: #{arg_machines}")

          arg_machines.each do |m|
            e = machine_to_entry(m)
            @machines[e.id] = e
          end
        end

        @logger.debug("machines: #{@machines.keys}")

        @machines.each do |uuid, data|
          yield data
        end
      end

      protected

      # Converts a machine to a machine index entry
      #
      # @param [Hashicorp::Vagrant::Sdk::Args::Target]
      # @return [Vagrant::MachineIndex::Entry] 
      def machine_to_entry(machine)
        @logger.debug("transforming machine #{machine}")
        conn = @client.broker.dial(machine.stream_id)
        target_service = Hashicorp::Vagrant::Sdk::TargetService::Stub.new(conn.to_s, :this_channel_is_insecure)
        machine = target_service.specialize(Google::Protobuf::Any.new)
        m = Hashicorp::Vagrant::Sdk::Args::Target::Machine.decode(machine.value)
        conn = @client.broker.dial(m.stream_id)
        machine_client = VagrantPlugins::CommandServe::Client::Machine.new(conn.to_s)
        raw = {
          "name" => machine_client.get_name(),
          "local_data_path" => machine_client.get_local_data_path(),
          # TODO: get the provider!
          "provider" => "virtualbox",
          "state" => machine_client.get_state().id,
          "vagrantfile_name" => machine_client.get_vagrantfile_name(),
          "vagrantfile_path" => machine_client.get_vagrantfile_path(),
          "machine_client" => machine_client,
        }
        id = machine_client.get_id()
        @logger.debug("machine id: #{id}")
        entry = Vagrant::MachineIndex::Entry.new(
          id=id, raw=raw
        )
        return entry
      end
    end
  end
end
