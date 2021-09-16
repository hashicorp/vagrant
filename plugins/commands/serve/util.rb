module VagrantPlugins
  module CommandServe
    module Util
      # Extracts connection information from a proto
      # and establishes a new connection
      module Connector
        def connect(proto:, broker:)
          if(proto.target.to_s.empty?)
            conn = broker.dial(proto.stream_id)
          else
            conn = proto.target.to_s.start_with?('/') ?
              "unix:#{proto.target}" :
              proto.target.to_s
          end
          conn.to_s
        end
      end

      # Requires a broker to be set when initializing an
      # instance and adds an accessor to the broker
      module HasBroker
        def broker
          @broker
        end

        def initialize(*args, **opts, &block)
          @broker = opts.delete(:broker)
          raise ArgumentError,
            "Expected `Broker' to be provided" if @broker.nil?
          super
        end
      end

      module HasMapper
        def mapper
          @mapper
        end

        def initialize(*args, **opts, &block)
          @mapper = Mappers.new(broker) if respond_to?(:broker)
          super
        end
      end

      # Adds exception logging to all public instance methods
      module ExceptionLogger
        def self.prepended(klass)
          klass.const_set(:LOGGER, Log4r::Logger.new(klass.name.downcase))
          klass.public_instance_methods(false).each do |m_name|
            klass.define_method(m_name) do |*args, **opts, &block|
              begin
                super(*args, **opts, &block)
              rescue => err
                self.class.const_get(:LOGGER).error(err)
                self.class.const_get(:LOGGER).debug("#{err.class}: #{err}\n#{err.backtrace.join("\n")}")
                raise
              end
            end
          end
        end
      end
    end
  end
end
