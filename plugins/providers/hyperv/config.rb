require "vagrant"

module VagrantPlugins
  module HyperV
    class Config < Vagrant.plugin("2", :config)
      # Allowed automatic start actions for VM
      ALLOWED_AUTO_START_ACTIONS = [
        "Nothing".freeze,
        "StartIfRunning".freeze,
        "Start".freeze
      ].freeze

      # Allowed automatic stop actions for VM
      ALLOWED_AUTO_STOP_ACTIONS = [
        "ShutDown".freeze,
        "TurnOff".freeze,
        "Save".freeze
      ].freeze

      # @return [Integer] Seconds to wait for an IP address when booting
      attr_accessor :ip_address_timeout
      # @return [Integer] Memory size in MB
      attr_accessor :memory
      # @return [Integer] Maximum memory size in MB. Enables dynamic memory.
      attr_accessor :maxmemory
      # @return [Integer] Number of CPUs
      attr_accessor :cpus
      # @return [String] Name of the VM (Shown in the Hyper-V Manager)
      attr_accessor :vmname
      # @return [Integer] VLAN ID for network interface
      attr_accessor :vlan_id
      # @return [String] MAC address for network interface
      attr_accessor :mac
      # @return [Boolean] Create linked clone instead of full clone
      # @note **DEPRECATED** use #linked_clone instead
      attr_accessor :differencing_disk
      # @return [Boolean] Create linked clone instead of full clone
      attr_accessor :linked_clone
      # @return [String] Automatic action on start of host. Default: Nothing (Nothing, StartIfRunning, Start)
      attr_accessor :auto_start_action
      # @return [String] Automatic action on stop of host. Default: ShutDown (ShutDown, TurnOff, Save)
      attr_accessor :auto_stop_action
      # @return [Boolean] Enable automatic checkpoints. Default: false
      attr_accessor :enable_checkpoints
      # @return [Boolean] Enable virtualization extensions
      attr_accessor :enable_virtualization_extensions
      # @return [Hash] Options for VMServiceIntegration
      attr_accessor :vm_integration_services

      def initialize
        @ip_address_timeout = UNSET_VALUE
        @memory = UNSET_VALUE
        @maxmemory = UNSET_VALUE
        @cpus = UNSET_VALUE
        @vmname = UNSET_VALUE
        @vlan_id = UNSET_VALUE
        @mac = UNSET_VALUE
        @linked_clone = UNSET_VALUE
        @differencing_disk = UNSET_VALUE
        @auto_start_action = UNSET_VALUE
        @auto_stop_action = UNSET_VALUE
        @enable_virtualization_extensions = UNSET_VALUE
        @enable_checkpoints = UNSET_VALUE
        @vm_integration_services = {
            guest_service_interface: UNSET_VALUE,
            heartbeat: UNSET_VALUE,
            key_value_pair_exchange: UNSET_VALUE,
            shutdown: UNSET_VALUE,
            time_synchronization: UNSET_VALUE,
            vss: UNSET_VALUE
        }
      end

      def finalize!
        @linked_clone = false if @linked_clone == UNSET_VALUE
        @differencing_disk = false if @differencing_disk == UNSET_VALUE
        @linked_clone ||= @differencing_disk
        @differencing_disk ||= @linked_clone
        if @ip_address_timeout == UNSET_VALUE
          @ip_address_timeout = 120
        end
        @memory = nil if @memory == UNSET_VALUE
        @maxmemory = nil if @maxmemory == UNSET_VALUE
        @cpus = nil if @cpus == UNSET_VALUE
        @vmname = nil if @vmname == UNSET_VALUE
        @vlan_id = nil if @vlan_id == UNSET_VALUE
        @mac = nil if @mac == UNSET_VALUE

        @auto_start_action = "Nothing" if @auto_start_action == UNSET_VALUE
        @auto_stop_action = "ShutDown" if @auto_stop_action == UNSET_VALUE
        @enable_virtualization_extensions = false if @enable_virtualization_extensions == UNSET_VALUE
        if @enable_checkpoints == UNSET_VALUE
          @enable_checkpoints = false
        else
          @enable_checkpoints = !!@enable_checkpoints
        end
        @vm_integration_services.delete_if{|_, v| v == UNSET_VALUE }
        @vm_integration_services = nil if @vm_integration_services.empty?
      end

      def validate(machine)
        errors = _detected_errors

        if !ALLOWED_AUTO_START_ACTIONS.include?(auto_start_action)
          errors << I18n.t("vagrant.hyperv.config.invalid_auto_start_action", action: auto_start_action,
            allowed_actions: ALLOWED_AUTO_START_ACTIONS.join(", "))
        end

        if !ALLOWED_AUTO_STOP_ACTIONS.include?(auto_stop_action)
          errors << I18n.t("vagrant.hyperv.config.invalid_auto_stop_action", action: auto_stop_action,
            allowed_actions: ALLOWED_AUTO_STOP_ACTIONS.join(", "))
        end

        {"Hyper-V" => errors}
      end
    end
  end
end
