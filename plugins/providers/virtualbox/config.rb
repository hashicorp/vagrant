module VagrantPlugins
  module ProviderVirtualBox
    class Config < Vagrant.plugin("2", :config)
      # Vagrant by default will make "smart" decisions to enable/disable
      # the NAT DNS proxy. If this is set to `true`, then the DNS proxy
      # will not be enabled, and it is up to the end user to do it.
      #
      # @return [Boolean]
      attr_accessor :auto_nat_dns_proxy

      # If true, will check if guest additions are installed and up to
      # date. By default, this is true.
      #
      # @return [Boolean]
      attr_accessor :check_guest_additions

      # An array of customizations to make on the VM prior to booting it.
      #
      # @return [Array]
      attr_reader :customizations

      # If true, unused network interfaces will automatically be deleted.
      # This defaults to false because the detection does not work across
      # multiple users, and because on Windows this operation requires
      # administrative privileges.
      #
      # @return [Boolean]
      attr_accessor :destroy_unused_network_interfaces

      # If set to `true`, then VirtualBox will be launched with a GUI.
      #
      # @return [Boolean]
      attr_accessor :gui

      # This should be set to the name of the machine in the VirtualBox
      # GUI.
      #
      # @return [String]
      attr_accessor :name

      # Whether or not this VM has a functional vboxsf filesystem module.
      # This defaults to true. If you set this to false, then the "virtualbox"
      # synced folder type won't be valid.
      #
      # @return [Boolean]
      attr_accessor :functional_vboxsf

      # The defined network adapters.
      #
      # @return [Hash]
      attr_reader :network_adapters

      def initialize
        @auto_nat_dns_proxy = UNSET_VALUE
        @check_guest_additions = UNSET_VALUE
        @customizations   = []
        @destroy_unused_network_interfaces = UNSET_VALUE
        @functional_vboxsf = UNSET_VALUE
        @name             = UNSET_VALUE
        @network_adapters = {}
        @gui              = UNSET_VALUE

        # We require that network adapter 1 is a NAT device.
        network_adapter(1, :nat)
      end

      # Customize the VM by calling `VBoxManage` with the given
      # arguments.
      #
      # When called multiple times, the customizations will be applied
      # in the order given.
      #
      # The special `:name` parameter in the command will be replaced with
      # the unique ID or name of the virtual machine. This is useful for
      # parameters to `modifyvm` and the like.
      #
      # @param [Array] command An array of arguments to pass to
      # VBoxManage.
      def customize(*command)
        event   = command.first.is_a?(String) ? command.shift : "pre-boot"
        command = command[0]
        @customizations << [event, command]
      end

      # This defines a network adapter that will be added to the VirtualBox
      # virtual machine in the given slot.
      #
      # @param [Integer] slot The slot for this network adapter.
      # @param [Symbol] type The type of adapter.
      def network_adapter(slot, type, **opts)
        @network_adapters[slot] = [type, opts]
      end

      # Shortcut for setting memory size for the virtual machine.
      # Calls #customize internally.
      #
      # @param size [Integer, String] the memory size in MB
      def memory=(size)
        customize("pre-boot", ["modifyvm", :id, "--memory", size.to_s])
      end

      # Shortcut for setting CPU count for the virtual machine.
      # Calls #customize internally.
      #
      # @param count [Integer, String] the count of CPUs
      def cpus=(count)
        customize("pre-boot", ["modifyvm", :id, "--cpus", count.to_i])
      end

      def merge(other)
        super.tap do |result|
          c = customizations.dup
          c += other.customizations
          result.instance_variable_set(:@customizations, c)
        end
      end

      # This is the hook that is called to finalize the object before it
      # is put into use.
      def finalize!
        # Default is to auto the DNS proxy
        @auto_nat_dns_proxy = true if @auto_nat_dns_proxy == UNSET_VALUE

        if @check_guest_additions == UNSET_VALUE
          @check_guest_additions = true
        end

        if @destroy_unused_network_interfaces == UNSET_VALUE
          @destroy_unused_network_interfaces = false
        end

        if @functional_vboxsf == UNSET_VALUE
          @functional_vboxsf = true
        end

        # Default is to not show a GUI
        @gui = false if @gui == UNSET_VALUE

        # The default name is just nothing, and we default it
        @name = nil if @name == UNSET_VALUE
      end

      def validate(machine)
        errors = _detected_errors

        valid_events = ["pre-import", "pre-boot", "post-boot", "post-comm"]
        @customizations.each do |event, _|
          if !valid_events.include?(event)
            errors << I18n.t(
              "vagrant.virtualbox.config.invalid_event",
              event: event.to_s,
              valid_events: valid_events.join(", "))
          end
        end

        @customizations.each do |event, command|
          if event == "pre-import" && command.index(:id)
            errors << I18n.t("vagrant.virtualbox.config.id_in_pre_import")
          end
        end

        # Verify that internal networks are only on private networks.
        machine.config.vm.networks.each do |type, data|
          if data[:virtualbox__intnet] && type != :private_network
            errors << I18n.t("vagrant.virtualbox.config.intnet_on_bad_type")
            break
          end
        end

        { "VirtualBox Provider" => errors }
      end

      def to_s
        "VirtualBox"
      end
    end
  end
end
