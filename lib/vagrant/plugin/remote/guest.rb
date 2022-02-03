module Vagrant
  module Plugin
    module Remote
      class Guest
        # This module enables Guest for server mode
        module Remote

          # Add an attribute accesor for the client
          # when applied to the Guest class
          def self.prepended(klass)
            klass.class_eval do
              attr_accessor :client
            end
          end

          # @return [Boolean]
          def detect?(machine)
            client = machine.client.guest
            client.detect(machine)
          end
        end
      end
    end
  end
end
