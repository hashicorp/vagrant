# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      # Extracts connection information from a proto
      # and establishes a new connection
      module Connector
        def connect(proto:, broker:)
          if(proto.addr.to_s.empty?)
            conn = broker.dial(proto.stream_id)
          else
            conn = proto.addr.to_s.start_with?('/') ?
              "unix:#{proto.addr}" :
              proto.addr.to_s
          end
          conn.to_s
        end

        def load(raw, broker:)
          if raw.is_a?(String)
            n = self.respond_to?(:sdk_alias) ? self.sdk_alias : self.name
            lookup = n.split("::")
            idx = lookup.index("Client")
            if idx
              lookup.slice!(0, idx+1)
            end

            klass = lookup.inject(SDK::Args) do |const, name|
              const&.const_get(name)
            end
            if !klass
              raise NameError,
                "failed to locate required protobuf constant `SDK::Args::#{n}'\n\nArgs: #{SDK::Args.constants.inspect}"
            end
            begin
              raw = klass.decode(raw)
            rescue
              raw = klass.decode_json(raw)
            end
          end
          self.new(connect(proto: raw, broker: broker), raw, broker)
        end
      end
    end
  end
end
