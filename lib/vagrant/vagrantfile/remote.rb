# lib/remote.rb

module Vagrant
  class Vagrantfile
    module Remote
      # Add an attribute reader for the client
      # when applied to the Machine class
      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      def initialize(*_, client:)
        @client = client
        @config = ConfigWrapper.new(client: client)
      end

      # @return [Machine]
      def machine(name, provider, _, _, _)
        client.machine(name, provider)
      end

      def machine_names
        client.target_names
      end

      def machine_config(name, provider, _, _, validate_provider)
        client.machine_config(name, provider, validate_provider)
      end
    end

    class ConfigWrapper
      def initialize(client:)
        @client = client
        @logger = Log4r::Logger.new(self.class.name.downcase)
        @root = Vagrant::Config::V2::Root.new(Vagrant.plugin("2").local_manager.config)
      end

      def method_missing(*args, **opts, &block)
        case args.size
        when 1
          namespace = args.first
        when 2
          if args.first.to_s != "[]"
            raise ArgumentError,
                  "Expected #[] but received ##{args.first} on config wrapper"
          end
          namespace = args.last
        else
          #raise ArgumentError,
                @logger.error("Cannot handle wrapped request for: #{args.inspect}")
        end

        # TODO: Check args, opts, and block and return error if any are set
        @logger.info("config wrapper fetching config value for namespace: #{namespace}")
        begin
          @client.get_config(namespace)
        rescue => err
          @logger.warn("config wrapper failed to process request: #{args} Reason: #{err}")
          @root.send(*args)
        end
      end
    end
  end
end
