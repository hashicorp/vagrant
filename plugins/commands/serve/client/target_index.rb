module VagrantPlugins
  module CommandServe
    module Client
      class TargetIndex

        extend Util::Connector

        attr_reader :client
        attr_reader :broker

        def initialize(conn, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::targetindex")
          @logger.debug("connecting to target index service on #{conn}")
          @client = SDK::TargetIndexService::Stub.new(conn, :this_channel_is_insecure)
          @broker = broker
        end

        def self.load(raw_index, broker:)
          m = raw_index.is_a?(String) ? SDK::Args::TargetIndex.decode(raw_index) : raw_index
          self.new(connect(proto: m, broker: broker), broker)
        end

        # @param [string]
        # @return [Boolean] true if delete is successful
        def delete(ident)
          @logger.debug("deleting machine with id #{ident} from index")
          client.delete(
            SDK::TargetIndex::TargetIdentifier.new(
              id: ident
            )
          )
          true
        end

        # @param [string]
        # @return [MachineIndex::Entry]
        def get(ident)
          @logger.debug("getting machine with id #{ident} from index")
          begin
            resp = client.get(
              SDK::TargetIndex::TargetIdentifier.new(
                id: ident
              )
            )
            machine = Target.load(resp.target, broker: broker).to_machine
            Vagrant::MachineIndex::Entry.load(machine)
          rescue GRPC::NotFound
            nil
          end
        end

        # @param [string]
        # @return [Boolean]
        def include?(ident)
          @logger.debug("checking for machine with id #{ident} in index")
          client.includes(
            SDK::TargetIndex::TargetIdentifier.new(
              id: ident
            )
          ).exists
        end

        ## @param [Hashicorp::Vagrant::Sdk::Args::Target] target
        #
        # @param [MachineIndex::Entry]
        # @return [MachineIndex::Entry]
        def set(entry)
          @logger.debug("setting machine #{entry} in index")
          if entry.id.to_s.empty?
            raise ArgumentError,
              "Entry id must be set"
          end
          resp = client.get(
            SDK::TargetIndex::TargetIdentifier.new(
              id: ident
            )
          )
          machine = Target.load(resp.target, broker: broker).to_machine
          machine.set_name(entry.name)
          machine.set_state(entry.full_state)
          Vagrant::MachineIndex::Entry.load(machine)
        end

        # Get all targets
        # @return [Array<MachineIndex::Entry>]
        def all
          @logger.debug("getting all machines")
          client.all(Empty.new).targets.map do |t_ref|
            machine = Target.load(t_ref, broker: broker).to_machine
            Vagrant::MachineIndex::Entry.load(machine)
          end
        end
      end
    end
  end
end
