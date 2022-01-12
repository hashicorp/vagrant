module Vagrant
  module Plugin
    module Remote
      class Push
        # This module enables Push for server mode
        module Remote
          # Add an attribute accesor for the client
          # when applied to the Push class
          def self.prepended(klass)
            klass.class_eval do
              attr_accessor :client
            end
          end

          def initialize(env, config, **opts)
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
end
