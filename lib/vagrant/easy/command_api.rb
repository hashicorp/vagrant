require "delegate"

require "vagrant/easy/operations"

module Vagrant
  module Easy
    # This is the API that easy commands have access to. It is a subclass
    # of Operations so it has access to all those methods as well.
    class CommandAPI < DelegateClass(Operations)
      attr_reader :argv

      def initialize(vm, argv)
        super(Operations.new(vm))

        @argv = argv
        @vm   = vm
      end

      # Outputs an error message to the UI.
      #
      # @param [String] message Message to send.
      def error(message)
        @vm.ui.error(message)
      end

      # Outputs a normal message to the UI. Use this for any standard-level
      # messages.
      #
      # @param [String] message Message to send.
      def info(message)
        @vm.ui.info(message)
      end

      # Outputs a success message to the UI.
      #
      # @param [String] message Message to send.
       def success(message)
        @vm.ui.success(message)
      end
    end
  end
end
