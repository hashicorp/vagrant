module VagrantPlugins
  module CommandServe
    module Util
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
    end
  end
end
