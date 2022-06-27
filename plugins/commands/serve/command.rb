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
    autoload :Type, Vagrant.source_root.join("plugins/commands/serve/type").to_s
    autoload :Util, Vagrant.source_root.join("plugins/commands/serve/util").to_s

    class << self
      attr_accessor :broker
      attr_reader :cache
    end
    @cache = Util::Cacher.new

    class Command < Vagrant.plugin("2", :command)

      DEFAULT_BIND = "localhost"
      DEFAULT_PORT_RANGE = 40000..50000

      include Util::HasLogger

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
        logger.info("Starting Vagrant GRPC service addr=#{bind_addr.inspect} ports=#{ports.inspect}")
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
        CommandServe.broker = broker
        logger.debug("vagrant grpc broker started for grpc service addr=#{bind_addr} ports=#{ports.inspect}")

        [Broker::Streamer,
          Service::CommandService,
          Service::CommunicatorService,
          Service::ConfigService,
          Service::GuestService,
          Service::HostService,
          Service::InternalService,
          Service::ProviderService,
          Service::ProvisionerService,
          Service::PushService,
          Service::SyncedFolderService,
        ].each do |service_klass|
          service = service_klass.new(broker: broker)
          s.handle(service)
          health_checker.add_status(service_klass,
            Grpc::Health::V1::HealthCheckResponse::ServingStatus::SERVING)
          logger.debug("enabled Vagrant GRPC service: #{service_klass.name.split('::').last}")
        end

        s.handle(health_checker)

        logger.debug("writing connection informatation to stdout for go-plugin")
        STDOUT.puts "1|1|tcp|#{bind_addr}:#{port}|grpc"
        STDOUT.flush
        logger.info("Vagrant GRPC service is now running addr=#{bind_addr.inspect} port=#{port.inspect}")
        s.run_till_terminated_or_interrupted([1, 'int', 'SIGQUIT', 'SIGINT'])
      ensure
        logger.info("Vagrant GRPC service is shutting down")
      end
    end
  end
end

# Load in our conversions down here so all the autoload stuff is in place
require Vagrant.source_root.join("plugins/commands/serve/util/direct_conversions.rb").to_s
