require "vagrant"

module VagrantPlugins
  module HyperV
    class Config < Vagrant.plugin("2", :config)
      # The timeout to wait for an IP address when booting the machine,
      # in seconds.
      #
      # @return [Integer]
      attr_accessor :ip_address_timeout

      def initialize
        @ip_address_timeout = UNSET_VALUE
      end

      def finalize!
        if @ip_address_timeout == UNSET_VALUE
          @ip_address_timeout = 120
        end
      end

      def validate(machine)
        errors = _detected_errors

        { "Hyper-V" => errors }
      end
    end
  end
end
