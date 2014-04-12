module VagrantPlugins
  module Chef
    class CommandBuilder
      def initialize(machine, config, client_type)
        @machine     = machine
        @config      = config
        @client_type = client_type

        if client_type != :solo && client_type != :client
          raise 'Invalid client_type, expected solo or client'
        end
      end
    end
  end
end
