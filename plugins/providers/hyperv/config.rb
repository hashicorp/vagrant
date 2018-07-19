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
      # @return [Array] Config of disks and controllers
      attr_accessor :controllers
      
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
        @vm_integration_services = {}
        @controllers = []
      end

      def controller(controller={})
        #puts "hej: controller called in config.rb"  
        @controllers << controller
      end

      def finalize!
        if @differencing_disk != UNSET_VALUE
          @_differencing_disk_deprecation = true
        end
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
      end

      def validate(machine)
        errors = _detected_errors

        if @_differencing_disk_deprecation && machine
          machine.ui.warn I18n.t("vagrant_hyperv.config.differencing_disk_deprecation")
        end

        if !vm_integration_services.is_a?(Hash)
          errors << I18n.t("vagrant_hyperv.config.invalid_integration_services_type",
            received: vm_integration_services.class)
        else
          vm_integration_services.each do |key, value|
            if ![true, false].include?(value)
              errors << I18n.t("vagrant_hyperv.config.invalid_integration_services_entry",
                entry_name: name, entry_value: value)
            end
          end
        end

        if !ALLOWED_AUTO_START_ACTIONS.include?(auto_start_action)
          errors << I18n.t("vagrant_hyperv.config.invalid_auto_start_action", action: auto_start_action,
            allowed_actions: ALLOWED_AUTO_START_ACTIONS.join(", "))
        end

        if !ALLOWED_AUTO_STOP_ACTIONS.include?(auto_stop_action)
          errors << I18n.t("vagrant_hyperv.config.invalid_auto_stop_action", action: auto_stop_action,
            allowed_actions: ALLOWED_AUTO_STOP_ACTIONS.join(", "))
        end

        # This can happen when creating new on up.
        controllers.delete_if &:empty?
        
        controllers.each { |controller|
          #puts "controller: #{controller}"
          
          if ![:ide, :scsi].include?(controller[:type])
            errors << I18n.t("vagrant_hyperv.config.invalid_controller_type",
              type: controller[:type])
          end
       
          if [:ide].include?(controller[:type])
            errors << I18n.t("vagrant_hyperv.config.invalid_controller_type_ide_not_implemeented_yet",
              type: controller[:type])
          end

          if !controller[:disks].is_a?(Array)
            errors << I18n.t("vagrant_hyperv.config.invalid_controller_disks_is_not_an_array",
              disks: controller[:disks])
            next
          end
        
          next_is_size = false
          controller[:disks].each { |i|
            if !next_is_size
              if i.is_a?(String)
                if File.file?(i)
                  next_is_size = false
                
                  # TODO: This part not implemented yet.
                  errors << I18n.t("vagrant_hyperv.config.invalid_controller_disks_attaching_disks_not_implemented_yet",
                    element: i)
                else
                  next_is_size = true
                end
              else
                errors << I18n.t("vagrant_hyperv.config.invalid_controller_disks_element_is_not_a_string",
                  element: i)
              end
            else
              #puts "next_is_size: true"
              if !i.is_a?(Integer)
                errors << I18n.t("vagrant_hyperv.config.invalid_controller_disks_element_is_not_an_integer",
                  element: i)
              end
            end
          }
        }

        {"Hyper-V" => errors}
      end
    end
  end
end
