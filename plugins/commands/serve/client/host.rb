require "google/protobuf/well_known_types"

module VagrantPlugins
  module CommandServe
    module Client
      class Host
        include CapabilityPlatform

        extend Util::Connector

        attr_reader :broker
        attr_reader :client
        attr_reader :proto

        def initialize(conn, proto, broker=nil)
          @logger = Log4r::Logger.new("vagrant::command::serve::client::host")
          @logger.debug("connecting to host service on #{conn}")
          @client = SDK::HostService::Stub.new(conn, :this_channel_is_insecure)
          @broker = broker
          @proto = proto
        end

        def self.load(raw_host, broker:)
          g = raw_host.is_a?(String) ? SDK::Args::Host.decode(raw_host) : raw_host
          self.new(connect(proto: g, broker: broker), g, broker)
        end

        # @return [<String>] parents
        def parents
          @logger.debug("getting parents")
          req = SDK::FuncSpec::Args.new(
            args: []
          )
          res = client.parents(req)
          @logger.debug("got parents #{res}")
          res.parents
        end
      end
    end
  end
end
