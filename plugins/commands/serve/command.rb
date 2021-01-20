# NOTE: Update the load path so the proto files can properly require dependencies
$LOAD_PATH << File.expand_path("../service/proto/gen", __FILE__)

require_relative './service/proto/gen/ruby-server_pb'
require_relative './service/proto/gen/ruby-server_services_pb'
require_relative './service/proto/gen/plugin_pb'
require_relative './service/proto/gen/plugin_services_pb'

require_relative "./service/plugin_service"
require_relative "./service/provider_service"
require_relative "./service/command_service"
require_relative "./service/host_service"
require_relative "./service/internal_service"

require "optparse"
require 'grpc'
require 'grpc/health/checker'
require 'grpc/health/v1/health_services_pb'

module VagrantPlugins
  module CommandServe
    class Command < Vagrant.plugin("2", :command)

      DEFAULT_PORT = 10001

      def self.synopsis
        "start Vagrant server"
      end

      def execute
        options = {port: DEFAULT_PORT}

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant serve"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--port PORT", "Port to start the GRPC server on, defaults to 10001") do |port|
            options[:port] = port
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv
        serve(options[:port])
      end

      private

      def serve(port=10001)
        s = GRPC::RpcServer.new
        # Listen on port 10001 on all interfaces. Update for production use.
        s.add_http2_port("[::]:#{port}", :this_port_is_insecure)

        s.handle(VagrantPlugins::CommandServe::Serve::PluginService.new)
        s.handle(VagrantPlugins::CommandServe::Serve::ProviderService.new)
        s.handle(Service::InternalService.new)
        s.handle(Service::HostService.new)
        s.handle(Service::CommandService.new)

        health_checker = Grpc::Health::Checker.new
        health_checker.add_status(
          Service::InternalService,
          Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)
        health_checker.add_status(
          Service::HostService,
          Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)
        health_checker.add_status(
          Service::CommandService,
          Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)
        s.handle(health_checker)

        STDOUT.puts "1|1|tcp|127.0.0.1:#{port}|grpc"
        STDOUT.flush
        s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT', 'SIGINT'])
      end
    end
  end
end
