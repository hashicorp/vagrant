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

        def delete(machine)
          @logger.debug("deleting machine #{machine} from index")
        end

        def get(uuid)
          @logger.debug("getting machine with uuid #{uuid} from index")
        end

        def include?(uuid)
          @logger.debug("checking for machine with uuid #{uuid} in index")
        end

        def set(entry)
          @logger.debug("setting machine #{entry} in index")
        end
      end
    end
  end
end
