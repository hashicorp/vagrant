# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module VagrantPlugins
  module CommandServe
    module Util
      module ClientSetup
        def self.prepended(klass)
          klass.extend(Connector)
          klass.class_eval do
            attr_reader :broker, :client, :proto
          end
        end

        def initialize(conn, proto, broker=nil)
          n = self.class.respond_to?(:sdk_alias) ? self.class.sdk_alias : self.class.name
          lookup = n.split("::")
          idx = lookup.index("Client")
          if idx
            lookup.slice!(0, idx+1)
          end

          srv = "#{lookup.join}Service"

          @broker = broker
          @proto = proto
          srv_klass = SDK.const_get(srv)&.const_get(:Stub)
          if !srv_klass
            raise NameError,
              "failed to locate required protobuf constant `SDK::#{srv}'"
          end
          @client = srv_klass.new(conn, :this_channel_is_insecure)
        end

        def to_proto
          @proto
        end
      end
    end
  end
end
