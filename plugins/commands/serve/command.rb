require_relative "./service/plugin_service"
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
        options = {}

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
        options[:port] ||= DEFAULT_PORT
        serve(options[:port])
      end

      private

      def serve(port=10001)
        s = GRPC::RpcServer.new
        # Listen on port 10001 on all interfaces. Update for production use.
        s.add_http2_port("[::]:#{port}", :this_port_is_insecure)
      
        s.handle(VagrantPlugins::CommandServe::Serve::PluginService.new)
      
        health_checker = Grpc::Health::Checker.new
        health_checker.add_status(
          "Service::PluginService",
          Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)
        s.handle(health_checker)
      
        STDOUT.puts "1|1|tcp|127.0.0.1:#{port}|grpc"
        STDOUT.flush
        s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT', 'SIGINT'])
      end
    end
  end
end
