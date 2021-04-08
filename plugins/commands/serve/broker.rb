require "singleton"
require "thread"

module VagrantPlugins
  module CommandServe
    # This is a Ruby implementation of the GRPC Broker found
    # within the go-plugin library. This can be used to provide
    # feature parity with golang based go-plugins
    class Broker
      include Singleton

      # Protobuf connection information
      Info = ::Plugin::ConnInfo

      # Hold connection information received about
      # available streams
      class Connection
        attr_reader :address, :network

        def initialize(address:, network:)
          @address = address
          @network = network
        end

        def to_s
          if network == "unix"
            "unix:#{address}"
          else
            address
          end
        end
      end

      # This is the streamer service required to process
      # broker information about connection streams. This
      # is passed to our internal broker to track streams
      # for internal use.
      class Streamer < ::Plugin::GRPCBroker::Service
        def start_stream(reqs, x)
          reqs.map do |req|
            Broker.instance.register(req)
          end
          nil
        end
      end

      # Create a new broker
      def initialize
        @streams_m = Mutex.new
        @streams = {}
      end

      # Register a stream
      #
      # @param [Plugin::ConnInfo] info Connection information from the broker
      # @return [nil]
      def register(info)
        @streams_m.synchronize do
          notifier = @streams[info.service_id]
          @streams[info.service_id] = Connection.new(
            network: info.network, address: info.address)
          if notifier
            notifier.broadcast
          end
        end
        nil
      end

      # Get connection information for a given ID
      #
      # @param [Integer] id Identifier for the stream
      # @return [Connection]
      # @note If stream information has not be received
      #       for the requested ID it will wait for the
      #       info.
      # TODO(spox): Should we add a timeout here similar
      #             to within go-plugin (hard coded 5s).
      def dial(id)
        catch(:found) do
          @streams_m.synchronize do
            v = @streams[id]
            throw :found, v if v.is_a?(Connection)
            if v.nil?
              v = @streams[id] = ConditionVariable.new
            end
            v.wait(@streams_m)
            @streams[id]
          end
        end
      end
    end
  end
end
