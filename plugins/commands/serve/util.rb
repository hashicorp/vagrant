module VagrantPlugins
  module CommandServe
    module Util
      # Requires a broker to be set when initializing an
      # instance and adds an accessor to the broker
      module HasBroker
        def self.prepended(klass)
          klass.class_eval do
            attr_reader :broker
          end
        end
        def initialize(*args, **opts, &block)
          @broker = opts.delete(:broker)
          raise ArgumentError,
            "Expected `Broker' to be provided" if @broker.nil?
          super
        end
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
              Logger.error(err)
              Logger.debug("#{err.class}: #{err}\n#{err.backtrace.join("\n")}")
              raise
            end
          end
        end
      end
    end
  end
end
