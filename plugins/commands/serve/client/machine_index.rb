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

        # @param [Hashicorp::Vagrant::Sdk::Ref::Target] a ref for the machine to access.
        # @return [Hashicorp::Vagrant::Sdk::Ref::Target]
        def get(ref)
          @logger.debug("getting machine with ref #{ref} from index")
          resp = @client.get(ref)
          return resp
        end

        # @param [Hashicorp::Vagrant::Sdk::Ref::Target]
        # @return [Boolean]
        def include?(ref)
          @logger.debug("checking for machine with ref #{ref} in index")
          @client.includes(ref).exists
        end

        # @param [Hashicorp::Vagrant::Sdk::Args::Target] target
        # @return [Hashicorp::Vagrant::Sdk::Args::Target]  
        def set(target)
          @logger.debug("setting machine #{target} in index")
          @client.set(target)
        end
      end
    end
  end
end
