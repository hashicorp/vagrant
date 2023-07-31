# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

require "singleton"
require "thread"

module VagrantPlugins
  module CommandServe
    # This is a Ruby implementation of the GRPC Broker found
    # within the go-plugin library. This can be used to provide
    # feature parity with golang based go-plugins
    class Broker

      # Broker specific errors
      class Error < StandardError
        class StreamTimeout < Error; end
      end

      # Maximum number of seconds to wait for receiving stream connection information
      STREAM_WAIT_TIMEOUT = 5

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
        # @return [Broker]
        attr_reader :broker

        # Create a new streamer service
        #
        # @param broker [Broker] broker to register requests
        # @return [self]
        def initialize(broker:)
          super()
          @broker = broker
        end

        # Handle stream requests which include connection
        # information for stream IDs
        def start_stream(reqs, x)
          reqs.map do |req|
            broker.register(req)
          end
          nil
        end
      end

      # Create a server side broker
      def initialize(bind:, ports:)
        @bind = bind
        @ports = ports
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
      def dial(id)
        catch(:found) do
          @streams_m.synchronize do
            v = @streams[id]
            throw :found, v if v.is_a?(Connection)
            if v.nil?
              v = @streams[id] = ConditionVariable.new
            end
            v.wait(@streams_m, STREAM_WAIT_TIMEOUT)
            if v == @streams[id]
              raise Error::StreamTimeout,
                "Failed to receive connection information for stream `#{id}'"
            end
            @streams[id]
          end
        end
      end

      def inspect
        to_s
      end

      def client_for(stub)
      end

      class Client

        # Create a new broker
        def initialize(client:)
          @stream_id_m = Mutex.new
          @stream_id = 0
          @servers_m = Mutex.new
          @servers = {}
        end

        # @return [Integer] next stream id to use
        def next_id
          @stream_id_m.synchronize do
            @stream_id += 1
          end
        end

        # Accept a specific stream ID and immediately
        # serve a gRPC server on that stream ID.
        #
        # @param id [Integer] stream id
        # @param services [Array<Class>] list of services to serve
        def accept_and_serve(id, services)
          s = GRPC::RpcServer.new
          health_checker = Grpc::Health::Checker.new
          port = s.add_http2_port("#{bind_addr}:0", :this_port_is_insecure)
          services.each do |srv_klass|
            s.handle(srv_klass.new)
            health_checker.add_status(srv_klass,
              Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)
          end
          s.handle(health_checker)
          s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT', 'SIGINT'])
        end
      end
    end
  end
end
