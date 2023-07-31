# Copyright (c) HashiCorp, Inc.
# SPDX-License-Identifier: MIT

module Vagrant
  module Plugin
    module Remote
      # This class enables Push for server mode
      class Push < V2::Push
        # Add an attribute accesor for the client
        # when applied to the Push class
        attr_accessor :client

        def initialize(env, config, **opts)
          if opts[:client].nil?
            raise ArgumentError,
              "Remote client is required for `#{self.class.name}`"
          end
          @client = opts[:client]
          super(env, config)
        end

        def push
          client.push
        end
      end
    end
  end
end
