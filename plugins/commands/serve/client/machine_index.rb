module VagrantPlugins
  module CommandServe
    module Client
      class MachineIndex

        attr_reader :client

        def self.load(raw, broker:)
          conn = broker.dial(raw.stream_id)
          self.new(conn.to_s)
        end

        def initialize(conn)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::machineindex")
          @logger.debug("connecting to target index service on #{conn}")
          if !conn.nil?
            @client = SDK::TargetIndexService::Stub.new(conn, :this_channel_is_insecure)
          end
        end

        # @param [Hashicorp::Vagrant::Sdk::Args::Target]
        # @return [Boolean] true if delete is successful
        def delete(target)
          @logger.debug("deleting machine #{target} from index")
          @client.delete(target)
          true
        end

        # @param [String] uuid UUID for the machine to access.
        # @return [Hashicorp::Vagrant::Sdk::Args::Target]
        def get(uuid)
          @logger.debug("getting machine with uuid #{uuid} from index")
          req = TargetIndex::GetRequest.new(
            uuid: uuid
          )
          @client.get(req)
        end

        # @param [String] uuid
        # @return [Boolean]
        def include?(uuid)
          @logger.debug("checking for machine with uuid #{uuid} in index")
          req = TargetIndex::IncludesRequest.new(
            uuid: uuid
          )
          @client.includes(req).exists
        end

        # @param [Hashicorp::Vagrant::Sdk::Args::Target] target
        # @return [Hashicorp::Vagrant::Sdk::Args::Target]  
        def set(target)
          @logger.debug("setting machine #{entry} in index")
          @client.set(target)
        end
      end
    end
  end
end
