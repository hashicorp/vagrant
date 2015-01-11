require "vagrant"

module VagrantPlugins
  module HyperV
    class Config < Vagrant.plugin("2", :config)
      # The timeout to wait for an IP address when booting the machine,
      # in seconds.
      #
      # @return [Integer]
      attr_accessor :ip_address_timeout

      # The default VLAN ID for network interface for the virtual machine.
      #
      # @return [Integer]
      attr_accessor :vlan_id

      def initialize
        @ip_address_timeout = UNSET_VALUE
        @vlan_id  = UNSET_VALUE
      end

      def finalize!
        if @ip_address_timeout == UNSET_VALUE
          @ip_address_timeout = 120
        end

        if @vlan_id == UNSET_VALUE
          @vlan_id = 0
        end
      end

      def validate(machine)
        errors = _detected_errors

        { "Hyper-V" => errors }
      end
    end
  end
end
