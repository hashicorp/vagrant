require "vagrant"

module VagrantPlugins
  module HyperV
    class Config < Vagrant.plugin("2", :config)
      # The timeout to wait for an IP address when booting the machine,
      # in seconds.
      #
      # @return [Integer]
      attr_accessor :ip_address_timeout
      # The defined network adapters.
      #
      # @return [Hash]
      attr_reader :network_adapters

      attr_accessor :generation
      attr_accessor :memory
      attr_accessor :maxmemory
      attr_accessor :cpus
      attr_accessor :vmname

      def initialize
        @ip_address_timeout = UNSET_VALUE
        @network_adapters = {}
        @generation = "1"
        @memory = UNSET_VALUE
        @maxmemory = UNSET_VALUE
        @cpus = UNSET_VALUE
        @vmname = UNSET_VALUE

        # We require that network adapter 1 is a NAT device.
        network_adapter(1, :nat)
      end

       # This defines a network adapter that will be added to the VirtualBox
      # virtual machine in the given slot.
      #
      # @param [Integer] slot The slot for this network adapter.
      # @param [Symbol] type The type of adapter.
      def network_adapter(slot, type, **opts)
        @network_adapters[slot] = [type, opts]
       end

      def finalize!
        if @ip_address_timeout == UNSET_VALUE
          @ip_address_timeout = 120
        end
        @memory = nil if @memory == UNSET_VALUE
        @maxmemory = nil if @maxmemory == UNSET_VALUE
        @cpus = nil if @cpus == UNSET_VALUE 
        @vmname = nil if @vmname == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        { "Hyper-V" => errors }
      end
    end
  end
end
