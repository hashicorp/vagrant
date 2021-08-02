module Vagrant
  class MachineIndex
    # This module enables the MachineIndex for server mode
    module Remote

      # Add an attribute reader for the client
      # when applied to the MachineIndex class
      def self.prepended(klass)
        klass.class_eval do
          attr_reader :client
        end
      end

      # Initializes a MachineIndex
      def initialize(*args, **kwargs)
        @machines  = {}
        @machine_locks = {}
        @client = kwargs.key("client")
      end
    end
  end
end
