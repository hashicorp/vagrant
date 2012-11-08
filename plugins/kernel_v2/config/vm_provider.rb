module VagrantPlugins
  module Kernel_V2
    # Represents a single configured provider for a VM. This may or may
    # not be a valid provider.
    class VagrantConfigProvider
      attr_reader :name

      # Initializes a new provider configuration for a VM. This should
      # only be instantiated internally by calling `config.vm.provider`.
      #
      # @param [Symbol] name The name of the provider that is registered.
      def initialize(name)
        @name = name
      end
    end
  end
end
