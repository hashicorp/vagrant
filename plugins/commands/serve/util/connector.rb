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

        def load(raw, broker:)
          if raw.is_a?(String)
            srv = self.class.name.split('::').last
            klass = SDK::Args.const_get(srv)
            if !klass
              raise NameError,
                "failed to locate required protobuf constant `SDK::Args::#{srv}'"
            end
            raw = klass.decode(raw)
          end
          self.new(connect(proto: raw, broker: broker), raw, broker)
        end
      end
    end
  end
end
