module VagrantPlugins
  module CommandServe
    module Util
      module ClientSetup
        def self.prepended(klass)
          klass.class_eval do
            attr_reader :broker, :client, :proto
          end
        end

        def initialize(conn, proto, broker=nil)
          srv = self.class.name.split('::').last
          logger.debug("connecting to #{srv.downcase} service on #{conn}")
          @broker = broker
          @proto = proto
          srv_klass = SDK.const_get("#{srv}Service")&.const_get(:Stub)
          if !srv_klass
            raise NameError,
              "failed to locate required protobuf constant `SDK::#{srv}Service'"
          end
          @client = srv_klass.new(conn, :this_channel_is_insecure)
        end
      end
    end
  end
end
