$LOAD_PATH << Vagrant.source_root.join("lib/vagrant/protobufs").to_s
$LOAD_PATH << Vagrant.source_root.join("lib/vagrant/protobufs/proto").to_s
$LOAD_PATH << Vagrant.source_root.join("lib/vagrant/protobufs/proto/vagrant_plugin_sdk").to_s

require 'vagrant/protobufs/proto/vagrant_server/server_pb'
require 'vagrant/protobufs/proto/vagrant_server/server_services_pb'
require 'vagrant/protobufs/proto/ruby_vagrant/ruby-server_pb'
require 'vagrant/protobufs/proto/ruby_vagrant/ruby-server_services_pb'
require 'vagrant/protobufs/proto/vagrant_plugin_sdk/plugin_pb'
require 'vagrant/protobufs/proto/vagrant_plugin_sdk/plugin_services_pb'
require 'vagrant/protobufs/proto/plugin/grpc_broker_pb'
require 'vagrant/protobufs/proto/plugin/grpc_broker_services_pb'

require "optparse"
require 'grpc'
require 'grpc/health/checker'
require 'grpc/health/v1/health_services_pb'

module VagrantPlugins
  module CommandServe
    # Simple constant aliases to reduce namespace typing
    SDK = Hashicorp::Vagrant::Sdk
    SRV = Hashicorp::Vagrant
    Empty = Google::Protobuf::Empty

    autoload :Broker, Vagrant.source_root.join("plugins/commands/serve/broker").to_s
    autoload :Client, Vagrant.source_root.join("plugins/commands/serve/client").to_s
    autoload :Mappers, Vagrant.source_root.join("plugins/commands/serve/mappers").to_s
    autoload :Service, Vagrant.source_root.join("plugins/commands/serve/service").to_s
    autoload :Util, Vagrant.source_root.join("plugins/commands/serve/util").to_s

    class Command < Vagrant.plugin("2", :command)

      DEFAULT_BIND = "localhost"
      DEFAULT_PORT_RANGE = 40000..50000

      def self.synopsis
        "start Vagrant server"
      end

      def execute
        options = {
          bind: DEFAULT_BIND,
          min_port: DEFAULT_PORT_RANGE.first,
          max_port: DEFAULT_PORT_RANGE.last,
        }

        opts = OptionParser.new do |o|
          o.banner = "Usage: vagrant serve"
          o.separator ""
          o.separator "Options:"
          o.separator ""

          o.on("--bind ADDR", "Bind to specific address. Default: #{DEFAULT_BIND}") do |addr|
            options[:bind] = addr
          end

          o.on("--min-port PORT", "Minimum port number to use. Default: #{DEFAULT_PORT_RANGE.first}") do |port|
            options[:min_port] = port
          end

          o.on("--max-port PORT", "Maximum port number to use. Default: #{DEFAULT_PORT_RANGE.last}") do |port|
            options[:max_port] = port
          end
        end

        # Parse the options
        argv = parse_options(opts)
        return if !argv

        ports = options[:min_port].to_i .. options[:max_port].to_i
        serve(options[:bind], ports)
      end

      private

      def serve(bind_addr = "localhost", ports = DEFAULT_PORT_RANGE)
        # Set vagrant in server mode
        Vagrant.enable_server_mode!

        s = GRPC::RpcServer.new
        port = nil
        ports.each do |p|
          begin
            port = s.add_http2_port("#{bind_addr}:#{p}", :this_port_is_insecure)
            break
          rescue RuntimeError
            # Assuming port in use, trying next
          end
        end
        raise "Failed to bind GRPC server listener" if port.nil?

        health_checker = Grpc::Health::Checker.new
        broker = Broker.new(bind: bind_addr, ports: ports)

        [Service::InternalService, Service::ProviderService, Service::GuestService,
          Service::HostService, Service::CommandService, Broker::Streamer].each do |service_klass|
          service = service_klass.new(broker: broker)
          s.handle(service)
          health_checker.add_status(service_klass,
            Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)
        end

        s.handle(health_checker)

        STDOUT.puts "1|1|tcp|127.0.0.1:#{port}|grpc"
        STDOUT.flush
        s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT', 'SIGINT'])
      end
    end
  end
end
