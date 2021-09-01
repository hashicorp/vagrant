require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      class StateBag

        extend Util::Connector

        attr_reader :broker
        attr_reader :client
        attr_reader :proto

        def initialize(conn, proto, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::statebag")
          @logger.debug("connecting to state ba service on #{conn}")
          @client = SDK::StateBagService::Stub.new(conn, :this_channel_is_insecure)
          @broker = broker
          @proto = proto
        end

        def self.load(raw_statebag, broker:)
          s = raw_statebag.is_a?(String) ? SDK::Args::StateBag.decode(raw_statebag) : raw_statebag
          self.new(connect(proto: s, broker: broker), s, broker)
        end

        # @param [String]
        # @return [String]
        def get(key)
          req = SDK::StateBag::GetRequest.new(
            key: key
          )
          client.get(req).value
        end

        # @param [String]
        # @return [String, Boolean]
        def get_ok(key)
          req = SDK::StateBag::GetRequest.new(
            key: key
          )
          resp = client.get_ok(req)
          return resp.value, resp.ok
        end

        # @param [String, String]
        # @return []
        def put(key, val)
          req = SDK::StateBag::PutRequest.new(
            key: key, value: val
          )
          client.put(req)
        end

        # @param [String]
        # @return []
        def remove(key)
          req = SDK::StateBag::RemoveRequest.new(
            key: key
          )
          client.remove(req)
        end
      end
    end
  end
end
