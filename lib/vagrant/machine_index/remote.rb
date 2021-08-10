module Vagrant
  class MachineIndex
    # This module enables the MachineIndex for server mode
    module Remote

      attr_accessor :client

      attr_accessor :project_ref

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
      # @param [Entry] entry The entry to delete.
      # @return [Boolean] true if delete is successful
      def delete(entry)
        @machines.delete(entry.id)
        machine = entry.machine_client.ref
        @client.delete(machine)
      end

      # Accesses a machine by UUID
      #
      # @param [String] name for the machine to access.
      # @return [MachineIndex::Entry]
      def get(name)
        ref = Hashicorp::Vagrant::Sdk::Ref::Target.new(
          name: name,
          project: @project_ref
        )
        get_response = @client.get(ref)
        entry = machine_to_entry(get_response)
        entry
      end
      
      # Tests if the index has the given UUID.
      #
      # @param [String] name
      # @return [Boolean]
      def include?(name)
        ref = Hashicorp::Vagrant::Sdk::Ref::Target.new(
          name: name,
          project: @project_ref
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
      def each(reload=false)
        if reload
          arg_machines = @client.all()
          arg_machines.each do |m|
            @machines << machine_to_entry(m)
          end
        end

        @machines.each do |uuid, data|
          yield Entry.new(uuid, data.merge("id" => uuid))
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
          "state" => machine_client.get_state(),
          "vagrantfile_name" => machine_client.get_vagrantfile_name(),
          "vagrantfile_path" => machine_client.get_vagrantfile_path(),
          "machine_client" => machine_client,
        }
        entry = Vagrant::MachineIndex::Entry.new(
          id=machine_client.resource_id, raw=raw
        )
        return entry
      end
    end
  end
end
