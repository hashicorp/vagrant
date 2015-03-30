require "vagrant"

module VagrantPlugins
  module HyperV
    class Config < Vagrant.plugin("2", :config)
      
      attr_accessor :ip_address_timeout # Time to wait for an IP address when booting, in seconds @return [Integer]
      attr_accessor :memory #  Memory size in mb @return [Integer]
      attr_accessor :maxmemory # Maximal memory size in mb enables dynamical memory allocation @return [Integer]
      attr_accessor :cpus # Number of cpu's @return [Integer]
      attr_accessor :vmname # Name that will be shoen in Hyperv Manager @return [String]
      attr_accessor :vlan_id # VLAN ID for network interface for the virtual machine. @return [Integer]

      def initialize
        @ip_address_timeout = UNSET_VALUE
        @memory = UNSET_VALUE
        @maxmemory = UNSET_VALUE
        @cpus = UNSET_VALUE
        @vmname = UNSET_VALUE
        @vlan_id  = UNSET_VALUE
      end

      def finalize!
        if @ip_address_timeout == UNSET_VALUE
          @ip_address_timeout = 120
        end
        @memory = nil if @memory == UNSET_VALUE
        @maxmemory = nil if @maxmemory == UNSET_VALUE
        @cpus = nil if @cpus == UNSET_VALUE 
        @vmname = nil if @vmname == UNSET_VALUE
        @vlan_id = nil if @vlan_id == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        { "Hyper-V" => errors }
      end
    end
  end
end
