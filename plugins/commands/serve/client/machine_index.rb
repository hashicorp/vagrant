module VagrantPlugins
  module CommandServe
    module Client
      class MachineIndex

        attr_reader :client
        attr_reader :broker

        def self.load(raw, broker:)
          conn = broker.dial(raw.stream_id)
          self.new(conn.to_s, broker)
        end

        def initialize(conn, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::machineindex")
          @logger.debug("connecting to target index service on #{conn}")
          if !conn.nil?
            @client = SDK::TargetIndexService::Stub.new(conn, :this_channel_is_insecure)
          end
          @broker = broker
        end

        # @param [string]
        # @return [Boolean] true if delete is successful
        def delete(uuid)
          @logger.debug("deleting machine with id #{uuid} from index")
          ref = Hashicorp::Vagrant::Sdk::TargetIndex::TargetIdentifier.new(
            id: uuid
          )
          @client.delete(ref)
          true
        end

        # @param [string]
        # @return [MachineIndex::Entry]
        def get(uuid)
          @logger.debug("getting machine with id #{uuid} from index")
          ref = Hashicorp::Vagrant::Sdk::TargetIndex::TargetIdentifier.new(
            id: uuid
          )
          resp = @client.get(ref)
          return machine_to_entry(resp)
        end

        # @param [string]
        # @return [Boolean]
        def include?(uuid)
          @logger.debug("checking for machine with id #{uuid} in index")
          ref = Hashicorp::Vagrant::Sdk::TargetIndex::TargetIdentifier.new(
            id: uuid
          )
          @client.includes(ref).exists
        end

        ## @param [Hashicorp::Vagrant::Sdk::Args::Target] target
        #
        # @param [MachineIndex::Entry]
        # @return [MachineIndex::Entry]
        def set(entry)
          @logger.debug("setting machine #{entry} in index")
          ref = Hashicorp::Vagrant::Sdk::TargetIndex::TargetIdentifier.new(
            id: entry.id
          )
          if entry.id.nil? 
            raise "Entry id should not be nil!"
          end
          machine = machine_arg_to_machine_client(@client.get(ref))
          machine.set_name(entry.name)
          machine.set_state(entry.full_state)
          machine_client_to_entry(machine)
        end

        # Get all targets
        # @return [Array<MachineIndex::Entry>]  
        def all()
          @logger.debug("getting all machines")
          req = Google::Protobuf::Empty.new
          resp = @client.all(req)
          arg_machines = resp.targets
          machine_entries = []
          arg_machines.each do |m|
            machine_entries << machine_to_entry(m)
          end
          machine_entries
        end

        protected 

        # Converts a Args::Target to a machine client
        #
        # @param [Hashicorp::Vagrant::Sdk::Args::Target]
        # @return [VagrantPlugins::CommandServe::Client::Machine] 
        def machine_arg_to_machine_client(machine)
          @logger.debug("transforming machine #{machine}")
          conn = @broker.dial(machine.stream_id)
          target_service = Hashicorp::Vagrant::Sdk::TargetService::Stub.new(conn.to_s, :this_channel_is_insecure)
          machine = target_service.specialize(Google::Protobuf::Any.new)
          m = Hashicorp::Vagrant::Sdk::Args::Target::Machine.decode(machine.value)
          conn = @broker.dial(m.stream_id)
          VagrantPlugins::CommandServe::Client::Machine.new(conn.to_s)
        end

        # Converts a machine client to a machine index entry
        #
        # @param [VagrantPlugins::CommandServe::Client::Machine] 
        # @return [Vagrant::MachineIndex::Entry] 
        def machine_client_to_entry(machine_client)
          state = machine_client.get_state()
          raw = {
            "name" => machine_client.get_name(),
            "local_data_path" => machine_client.get_local_data_path(),
            # TODO: get the provider!
            "provider" => "virtualbox",
            "full_state" => state,
            "state" => state.id,
            "vagrantfile_name" => machine_client.get_vagrantfile_name(),
            "vagrantfile_path" => machine_client.get_vagrantfile_path(),
          }
          id = machine_client.get_id()
          @logger.debug("machine id: #{id}")
          Vagrant::MachineIndex::Entry.new(
            id=id, raw=raw
          )
        end

        # Converts a machine to a machine index entry
        #
        # @param [Hashicorp::Vagrant::Sdk::Args::Target]
        # @return [Vagrant::MachineIndex::Entry] 
        def machine_to_entry(machine)
          machine_client = machine_arg_to_machine_client(machine)
          machine_client_to_entry(machine_client)
        end
      end
    end
  end
end
