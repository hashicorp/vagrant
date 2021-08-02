module VagrantPlugins
  module CommandServe
    module Client
      class MachineIndex

        attr_reader :client

        def initialize(conn)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::machine")
          @logger.debug("connecting to target index service on #{conn}")
          if !conn.nil?
            @client = SDK::TargetIndexService::Stub.new(conn, :this_channel_is_insecure)
          end
        end

        def delete(machine)
        end

        def get(uuid)
        end

        def include?(uuid)
        end

        def set(entry)
        end
      end
    end
  end
end
