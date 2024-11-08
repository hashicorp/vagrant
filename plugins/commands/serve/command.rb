# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: BUSL-1.1

Vagrant.require "optparse"

module VagrantPlugins
  module CommandServe
    autoload :Broker, Vagrant.source_root.join("plugins/commands/serve/broker").to_s
    autoload :Client, Vagrant.source_root.join("plugins/commands/serve/client").to_s
    autoload :Mappers, Vagrant.source_root.join("plugins/commands/serve/mappers").to_s
    autoload :Service, Vagrant.source_root.join("plugins/commands/serve/service").to_s
    autoload :Type, Vagrant.source_root.join("plugins/commands/serve/type").to_s
    autoload :Util, Vagrant.source_root.join("plugins/commands/serve/util").to_s
    autoload :SDK, Vagrant.source_root.join("plugins/commands/serve/constants").to_s
    autoload :SRV, Vagrant.source_root.join("plugins/commands/serve/constants").to_s
    autoload :Empty, Vagrant.source_root.join("plugins/commands/serve/constants").to_s

    class << self
      attr_accessor :broker
      attr_accessor :server
      attr_reader :cache

      # Loads the required dependencies for this command. This is isolated
      # into a method so that the dependencies can be loaded just in time when
      # the command is actually executed.
      def load_dependencies!
        return if @dependencies_loaded
        Vagrant.require 'grpc'
        Vagrant.require 'grpc/health/checker'
        Vagrant.require 'grpc/health/v1/health_services_pb'

        # Add conversion patches
        require Vagrant.source_root.join("plugins/commands/serve/util/direct_conversions.rb").to_s

        # Mark dependencies as loaded
        @dependencies_loaded = true
      end
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
        # Load dependencies before we start
        CommandServe.load_dependencies!

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

        logger.debug("writing connection information to stdout for go-plugin")
        STDOUT.puts "1|1|tcp|#{bind_addr}:#{port}|grpc"
        STDOUT.flush
        logger.info("Vagrant GRPC service is now running addr=#{bind_addr.inspect} port=#{port.inspect}")
        VagrantPlugins::CommandServe.server = s
        s.run_till_terminated_or_interrupted(['EXIT', 'HUP', 'INT', 'QUIT', 'ABRT'])
        0
      ensure
        VagrantPlugins::CommandServe.server = nil
        logger.info("Vagrant GRPC service shut down")
      end
    end
  end
end
